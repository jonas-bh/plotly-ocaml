module Type : sig
  type 'a t =
    | Float : float t
    | String : string t
    | Bool : bool t
    | Array : 'a t -> 'a array t
    | Object : Ezjsonm.value t

  type type_ = Type : _ t -> type_
end

module Value : sig
  type 'a t = 'a Type.t * 'a
  type value = 
    | Value : 'a t -> value
    | Object : (string * value) list -> value

  val float : float -> float t
  val string : string -> string t
  val bool : bool -> bool t
  val array : 'a Type.t -> 'a array -> 'a array t
  val object_ : Ezjsonm.value -> Ezjsonm.value t

  val to_json : value -> Ezjsonm.value
  val of_json : Ezjsonm.value -> value option
end

module Attribute : sig
  type t = string * Value.value
end

module Attributes : sig
  type t = Attribute.t list

  val float : string -> float -> Attribute.t list
  val string : string -> string -> Attribute.t list
  val bool : string -> bool -> Attribute.t list
  val array : string -> 'a Type.t -> 'a array -> Attribute.t list

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end

module Marker : sig
  type t = private Attribute.t list

  (** 
    Set a single color for all data points. 

    The color may be specified by its color name (e.g., ["LightBlue"]), hex code (e.g., ["#ADD8E6"]), or RGB(A) string (e.g., ["rgba(173, 216, 230, 1)"]). 
    The latter allows for specifying transparency.
  *)
  val color : string -> Attribute.t list

  (** 
    Set the colors for each of the data points, such that each color corresponds to a data point. 

    The colors may be specified by their color name (e.g., ["LightBlue"]), hex codes (e.g., ["#ADD8E6"]), or RGB(A) strings (e.g., ["rgba(173, 216, 230, 1)"]). 
    The latter allows for specifying transparency.
  *)
  val colors : string array -> Attribute.t list
  val marker : Attribute.t list list -> t

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end

module Data : sig
  type t = private Attribute.t list

  val mode : string -> t
  val name : string -> t
  val legendgroup : string -> t
  val labels : string array -> t
  val values : float array -> t
  val text : string array -> t
  val orientation : string -> t
  val x : float array -> t
  val y : float array -> t
  val z : float array -> t
  val showlegend : bool -> t

  (* The argument is splitted to build attributes [x] and [y] *)
  val xy : (float * float) array -> t

  (* The argument is splitted to build attributes [x], [y], and [z] *)
  val xyz : (float * float * float) array -> t

  val marker : Attribute.t list list -> t

  (* Build custom data attributes *)
  val data : Attribute.t list -> t

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end

module Layout : sig
  type t = private Attribute.t list

  val title : string -> t
  val barmode : string -> t
  val showlegend : bool -> t

  module Axis : sig
    (** Set axis title *)
    val axis_title : string -> string * Base.Value.value

    (** 
      Set axis type (e.g. ["linear"] or ["log"]) 
      
      See https://plotly.com/python/axes/ for more details.
    *)
    val axis_type : string -> string * Base.Value.value

    (** Set axis data range as (min, max) *)
    val axis_range : float -> float -> string * Base.Value.value

    (** Toggle grid display *)
    val axis_showgrid : bool -> string * Base.Value.value

    (** Toggle zero line display *)
    val axis_zeroline : bool -> string * Base.Value.value

    (** 
      Set tick label format
    
      See https://plotly.com/python/tick-formatting/ for more details.
    *)
    val axis_tickformat : string -> string * Base.Value.value
  end

  module Font : sig
    (** HTML font family - the typeface that will be applied by the web browser. The web browser can only apply a font if it is available on the system where it runs. Provide multiple font families, separated by commas, to indicate the order in which to apply fonts if they aren't available. *)
    val font_family : string -> string * Base.Value.value

    val font_size : float -> string * Base.Value.value

    val font_color : string -> string * Base.Value.value
  end

  (** Set the x-axis properties *)
  val xaxis : (string * Base.Value.value) list -> t

  (** Set the y-axis properties *)
  val yaxis : (string * Base.Value.value) list -> t

  (** Set the z-axis properties *)
  val zaxis : (string * Base.Value.value) list -> t

  (** Set the global font properties for the graph. 
  
  Note that fonts used in traces and other layout components inherit from the global font. *)
  val font : (string * Base.Value.value) list -> t

  val layout : Attribute.t list -> t

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end

module Graph : sig
  type t = { type_: string; data : Data.t }

  val scatter : Data.t list -> t
  val scatter3d : Data.t list -> t
  val bar : Data.t list -> t
  val pie : Data.t list -> t
  val histogram : Data.t list -> t

  (* Build custom graph *)
  val graph : string -> Data.t list -> t

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end

module Figure : sig
  type t =
    { graphs : Graph.t list;
      layout : Layout.t }

  val figure : Graph.t list -> Layout.t list -> t

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end
