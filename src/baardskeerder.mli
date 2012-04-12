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

type t
type tx
type k = string
type v = string

exception NOT_FOUND of k

val init : string -> unit
val make : string -> t
val close : t -> unit

val get_latest : t -> k -> v
val with_tx : t -> (tx -> unit) -> unit

val get   : tx -> k -> v
val set   : tx -> k -> v -> unit
val delete: tx -> k -> unit


module Logs :
  sig
    module Flog : functor(S: Store.STORE) -> Log.LOG with type 'a m = 'a S.m
    module Flog0 : functor(S: Store.STORE) -> Log.LOG with type 'a m = 'a S.m
  end

module Stores :
  sig
    module Memory : Store.STORE with type 'a m = 'a
    module Sync : Store.STORE with type 'a m = 'a
    module Lwt : Store.STORE with type 'a m = 'a Lwt.t
  end
