(*
 * This file is part of Baardskeerder.
 *
 * Copyright (C) 2011 Incubaid BVBA
 *
 * Baardskeerder is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Baardskeerder is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Baardskeerder.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Unix
open Tree
open Arg
open Log

let clock n f = 
  let t0 = Unix.gettimeofday () in
  let cb = 
    if n mod 10 = 0 
    then
      let step = n/ 10 in
      function 
	| 0 -> () 
	| i when i mod step = 0 ->
	    let ti = Unix.gettimeofday () in
	    let d = ti -. t0 in
	    Printf.printf "\t%i (%.2f)\n" i d
	| _ -> ()
    else failwith "bench size must be multiple of 10"
  in
  let () = f () n cb in
  let t1 = Unix.gettimeofday () in
  t1 -. t0

type progress_callback = int -> unit

let logs = Hashtbl.create 3
let () = Hashtbl.add logs "Flog0" (module Flog0: LOG)
let () = Hashtbl.add logs "Flog"  (module Flog : LOG)

let () = 
  let n  = ref 1_000_000 in
  let vs = ref 2_000 in
  let fn = ref "test.db" in
  let d = ref 4 in
  let dump = ref false in
  let log_name = ref "Flog" in
  let () = 
    Arg.parse [
      ("--value-size",Set_int vs, Printf.sprintf "size of the values in bytes (%i)" !vs);
      ("--file", Set_string fn, Printf.sprintf "file name for database (%S)" !fn);
      ("--bench-size",Set_int n,  Printf.sprintf "number of sets/gets/deletes (%i)" !n);
      ("--d", Set_int d, Printf.sprintf "1/2 of the fan-out (%i)" !d);
      ("--log-name", Set_string log_name, Printf.sprintf "name of the log implementation (%s)" !log_name);
      ("--dump", Set dump, Printf.sprintf "doesn't run a benchmark, but dumps info about the file");
    ]
      (fun _ ->()) 
      "simple baardskeerder benchmark"
  in
  let module MyLog = (val (Hashtbl.find logs !log_name) : LOG) in
  let module MyDB = DB(MyLog) in  
  let make_key i = Printf.sprintf "key_%08i" i in

  let set_loop db vs n (cb: progress_callback) = 
    let v = String.make vs 'x' in
    let set k v = MyDB.set db k v in
    let rec loop i = 
      let () = cb i in
      if i = n 
      then MyLog.sync db
      else
	let key = make_key i in
	let () = set key v in
	loop (i+1)
    in
    loop 0 
  in

  let get_loop db n (cb: progress_callback) = 
    let get k = MyDB.get db k in
    let rec loop i =
      let () = cb i in
      if i = n 
      then ()
      else
	let key = make_key i in
	let _ = get key in
	loop (i+1)
    in
    loop 0
  in

  let delete_loop db n (cb: progress_callback) = 
    let delete k = MyDB.delete db k in
    let rec loop i = 
      let () = cb i in
      if i = n 
      then MyLog.sync db
      else
	let key = make_key i in
	let () = delete key in
	loop (i+1)
    in
    loop 0 
  in


  if !dump then
    begin
      let db = MyLog.make !fn in
      MyLog.dump db;
      MyLog.close db
    end
  else
    begin
      let () = MyLog.init !fn ~d:!d in 
      let db = MyLog.make !fn in
      let () = Printf.printf "\niterations = %i\nvalue_size = %i\n%!" !n !vs in
      let () = Printf.printf "starting sets\n" in
      let d = clock !n (fun () -> set_loop db !vs) in
      Printf.printf "sets: %fs\n%!" d;
      let () = Printf.printf "starting gets\n" in
      let d2 = clock !n (fun () -> get_loop db) in
      Printf.printf "gets: %fs\n%!" d2;
      let () = Printf.printf "starting deletes\n" in
      let d3 = clock !n (fun () -> delete_loop db) in
      Printf.printf "deletes: %fs\n%!" d3;
      let () = MyLog.close db in
      ()
    end;;
