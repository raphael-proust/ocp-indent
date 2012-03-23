open Pos
open Reader
open Approx_lexer

type token = {
  region  : Region.t;
  token   : Approx_lexer.token;
  newlines: int;
  between : string;
  spaces  : int; (* = String.length between *)
  substr  : string;
  offset  : int;
}

type cons =
  | Cons of token * t * in_channel
  | Null

and t = cons lazy_t

let create path =
  let ic = open_in path in
  try
    let reader = LexReader.create_from_channel ic in
    let rec loop last =
      let token = LexReader.lex reader Approx_lexer.token_with_comments in
      let region = LexReader.region reader in
      let newlines = Region.start_line region - Region.end_line last in
      let between = Region.create (Region.snd last) (Region.fst region) in
      let between = LexReader.substring_of_region reader between in
      let spaces = String.length between in
      let offset = Region.start_column region - Region.start_column last in

      (* token's string *)
      let substr = LexReader.current_substring reader in
      assert (LexReader.substring_of_region reader region = substr);

      Cons ({ region; between; spaces; token; substr; newlines; offset },
            lazy (match token with
            | EOF -> Null
            | _ -> loop region),
            ic)
    in
    lazy (loop Region.zero)
  with
  | e -> raise e

let close = function
  | lazy Null -> ()
  | lazy (Cons (_, _, ic)) -> close_in ic

let next = function
  | lazy Null -> None
  | lazy (Cons (car, cdr, _ic)) -> Some (car, cdr)