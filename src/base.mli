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
  type value = Value : 'a t -> value

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

  val color : string -> Attribute.t list

  val colors : string array -> Attribute.t list

  val marker : Attribute.t list list -> t

  val to_json : t -> Ezjsonm.value
  val of_json : Ezjsonm.value -> t option
end
