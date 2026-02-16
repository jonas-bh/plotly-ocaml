open Js_of_ocaml

type data
type layout
type config

(* Plotly.newPlot(graphDiv, data, layout, config) *)
type plotly =
  < newPlot :
      Dom_html.divElement Js.t ->
      data Js.t Js.js_array Js.t ->
      layout Js.t ->
      config Js.t -> unit Js.meth;

    react :
      Dom_html.divElement Js.t ->
      data Js.t Js.js_array Js.t ->
      layout Js.t ->
      config Js.t -> unit Js.meth;

    validate :
      data Js.t Js.js_array Js.t ->
      layout Js.t ->
      Js.js_string Js.t Js.js_array Js.t Js.meth;
  >

val plotly : plotly Js.t

val create : Dom_html.divElement Js.t -> Plotly.Figure.t -> unit

(** Validate a figure using Plotly.js validate function.
    Returns a list of error messages (empty list means valid). *)
val validate : Plotly.Figure.t -> string list
