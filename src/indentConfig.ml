(**************************************************************************)
(*                                                                        *)
(*  Copyright 2011 Jun Furuse                                             *)
(*  Copyright 2013 OCamlPro                                               *)
(*                                                                        *)
(*  All rights reserved.  This file is distributed under the terms of     *)
(*  the GNU Public License version 3.0.                                   *)
(*                                                                        *)
(*  TypeRex is distributed in the hope that it will be useful,            *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU General Public License for more details.                          *)
(*                                                                        *)
(**************************************************************************)

  type t = {
    i_atom: char;
    i_base: int;
    i_type: int;
    i_in: int;
    i_with: int;
    i_match_clause: int;
  }

  let default = {
    i_atom = ' ';
    i_base = 2;
    i_type = 2;
    i_in = 0;
    i_with = 0;
    i_match_clause = 2;
  }
  
  let tab = {
    i_atom = '\t';
    i_base = 1;
    i_type = 1;
    i_in = 0;
    i_with = 0;
    i_match_clause = 1;
  }

  let presets = [
    "apprentice",
    { i_atom = ' '; i_base = 4; i_with = 2; i_in = 2; i_match_clause = 4; i_type = 4 };
    "normal",
    default;
    "JaneStreet",
    { i_atom = ' '; i_base = 2; i_with = 0; i_in = 0; i_match_clause = 2; i_type = 0 };
    "tab", tab
  ]

  let set t var_name value =
    try
      match var_name with
      | "atom" ->
        if String.length value = 1 then
          {t with i_atom = value.[0]}
        else
          raise (Invalid_argument "Atom takes one character")
      | "base" -> {t with i_base = int_of_string value}
      | "type" -> {t with i_type = int_of_string value}
      | "in" -> {t with i_in = int_of_string value}
      | "with" -> {t with i_with = int_of_string value}
      | "match_clause" -> {t with i_match_clause = int_of_string value}
      | _ -> raise (Invalid_argument var_name)
    with
    | Failure "int_of_string" ->
        let e = Printf.sprintf "%S should be an integer" value in
        raise (Invalid_argument e)

  let update_from_string indent s =
    List.fold_left
      (fun indent s -> match Util.string_split '=' (String.trim s) with
      | [var;value] -> set indent var value
      | [preset] ->
          (try List.assoc preset presets with
            Not_found -> raise (Invalid_argument preset))
      | _ -> raise (Invalid_argument s))
      indent
      (Util.string_split ',' s)

  let help =
    Printf.sprintf
      "Config syntax: <var>=<value>[,<var>=<value>...] or <preset>[,...]\n\
       \n\
       Indent configuration variables:\n\
      \  [variable]   [default] [help]\n\
      \  atom           '%c'    indentation atom\n\     
      \  base           %3d     base indent\n\
      \  type           %3d     indent of type definitions\n\
      \  in             %3d     indent after 'let in'\n\
      \  with           %3d     indent of match cases (before '|')\n\
      \  match_clause   %3d     indent inside match cases (after '->')\n\
       \n\
       Available configuration presets:%s\n\
       \n\
       The config can also be set in variable OCP_INDENT_CONFIG"
      default.i_atom
      default.i_base
      default.i_type
      default.i_in
      default.i_with
      default.i_match_clause
      (List.fold_left (fun s (name,_) -> s ^ " " ^ name) "" presets)

  let default =
    try
      update_from_string default (Sys.getenv ("OCP_INDENT_CONFIG"))
    with
    | Not_found -> default
    | Invalid_argument _ ->
        prerr_endline "Warning: invalid $OCP_INDENT_CONFIG";
        default
