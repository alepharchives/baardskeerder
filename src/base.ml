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

(* .. *)

type pos = int
type k = string
type v = string

type kp = k * pos
type leaf = kp list
type leaf_z = leaf * leaf

type index = pos * (kp list)
type index_z = 
  | Top of index
  | Loc of ((pos * (kp list)) * (kp list))

let leaf2s l = 
  let b = Buffer.create 128 in
  let add_s s = Buffer.add_string b s in
  let add_p p = Buffer.add_string b (Printf.sprintf "%i" p) in
  let pair k p = add_s (Printf.sprintf "%S" k); add_s ", "; add_p p in
  let rec loop = function
    | [] -> ()
    | [k,p] -> pair k p
    | (k,p) :: t -> pair k p; add_s "; "; loop t
  in
  add_s "[";
  loop l ;
  add_s "]";
  Buffer.contents b
    

let index2s (p0,rest) = 
  let b= Buffer.create 128 in
  Buffer.add_string b (Printf.sprintf "%i" p0);
  Buffer.add_string b ", ";
  Buffer.add_string b (leaf2s rest);
  Buffer.contents b

let leaf_find_delete leaf k = 
  let rec loop z = match z with
    | _, [] -> None
    | _, (k0,_)   :: _    when k < k0 ->  None
    | _, (k0,p0)  :: _    when k = k0 ->  Some (p0, z)
    | c, h :: t -> loop (h::c,t)
  in
  loop ([],leaf)

let index_find_set index k = 
  let rec loop z = match z with
    | Top (_ , (k0, _) :: _) when k < k0      -> z
    | Top ((p0, h :: t))                      -> let pre = p0, [h] in
						 let z' = Loc (pre, t) in
						 loop z'
    | Loc (_ , (ki,pi) :: _) when k < ki      -> z
    | Loc ( (p0,c) , ((ki,pi) as h :: t))     -> let pre  = p0, (h :: c) in
						 let z' = Loc (pre, t) in
						 loop z'
  in loop (Top index)

let indexz_pos = function
  | Top (_,(_,p0) :: _) -> p0
  | Loc (_,(_,pi) :: _) -> pi


let indexz_replace pos = function
  | Top (p0, kps) -> (pos,kps)
  | Loc ((p0,c), (k,px) :: t) ->
    let rec loop acc = function
      | [] -> p0, acc
      | h :: t -> loop ( h :: acc) t
    in
    loop ((k,pos)::t) c

let leafz_delete = function
  | c,h::t -> (List.rev c) @ t
  | _ -> failwith "leafz_delete"

let d = 2

let z2s (c,t) = Printf.sprintf "(%s,%s)" (leaf2s c) (leaf2s t)

let leafz_max (c,t) = List.length c + List.length t = 2 * d - 1
  
let leafz_left (c,t) = 
  match t with 
  | h :: t' -> (h::c, t') 
  | _ -> failwith "left?"

let leafz_right (c,t) = 
  match c with
  | h :: c' -> c', (h:: t)
  | _ -> failwith "right?"

let leafz_close (c,t) = (List.rev c) @ t

let leafz_balance ((c,t) as z) = 
  let ls = List.length  c in
  let n,move = 
    if ls > d 
    then
      ls - d, leafz_right
    else
      d - ls, leafz_left
  in
  let rec loop z = function
    | 0 -> z
    | i -> loop (move z) (i-1)
  in
  loop z n


 let leafz_split k pos (c,t) = 
  let l,r = leafz_balance (c, (k,pos)::t) in
  let lift = List.hd l in
  List.rev l, lift, r

let leaf_find_set leaf k = 
  let rec loop z = match z with
    | c, ((k0,p0) as h) :: t when k0 < k -> loop (h::c, t)
    | c, (k0,_ ) :: t when k0 = k -> c,t 
    | z -> z
  in
  loop ([],leaf)

let leafz_insert k p (c,t) = (List.rev c) @ (k,p) :: t

