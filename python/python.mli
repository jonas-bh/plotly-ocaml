type _ t = private Py.Object.t

type figure

val of_figure : Plotly.Figure.t -> figure t

val python_figure_to_json : figure t -> Ezjsonm.value

val show : ?renderer:string -> figure t -> unit
val write_image : figure t -> string -> unit
val validate : figure t -> (string list, string) result
(** Validate a figure using Plotly's Python validate function.
    Returns Ok [] if valid, or Error with description if invalid. *)