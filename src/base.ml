type (_, _) eq = Eq : ('a, 'a) eq

module Type = struct
  type 'a t =
    | Float : float t
    | String : string t
    | Bool : bool t
    | Array : 'a t -> 'a array t
    | Object : Ezjsonm.value t

  type type_ = Type : 'a t -> type_

  let rec eq : type a b . a t -> b t -> (a, b) eq option = fun a b ->
    match a, b with
    | Float, Float -> Some Eq
    | String, String -> Some Eq
    | Bool, Bool -> Some Eq
    | Object, Object -> Some Eq
    | Array a, Array b ->
        (match eq a b with
         | Some Eq -> Some Eq
         | _ -> None)
    | _ -> None

  let _eq = eq
end

module Value = struct
  type 'a t = 'a Type.t * 'a
  type value = 
    | Value : 'a t -> value
    | Object : (string * value) list -> value

  let float f : float t = Type.Float, f
  let string s : string t = Type.String, s
  let bool b : bool t = Type.Bool, b
  let array ty vs : 'a array t = Type.Array ty, vs
  let object_ obj : Ezjsonm.value t = Type.Object, obj

  let rec to_json v : Ezjsonm.value =
    match v with
    | Value (Type.Float, f) -> `Float f
    | Value (String, s) -> `String s
    | Value (Bool, b) -> `Bool b
    | Value (Object, obj) -> obj
    | Value (Array ty, xs) -> `A (List.map (fun x -> to_json (Value (ty, x))) @@ Array.to_list xs)
    | Object kvs -> `O (List.map (fun (k, v) -> k, to_json v) kvs)

  let rec of_json v =
    let open Option in
    match v with
    | `Float f -> Some (Value (float f))
    | `String s -> Some (Value (string s))
    | `Bool b -> Some (Value (bool b))
    | `O _ as obj -> Some (Value (object_ obj))
    | `A vs ->
        let* vs = mapM of_json vs in
        (match vs with
        | [] -> None
        | v::vs ->
            (match v with
            | Value (ty, _) ->
                let rec check acc = function
                  | [] -> Some (Value (Type.Array ty, Array.of_list @@ List.rev acc))
                  | v'::vs ->
                      (match v' with
                      | Value (ty', v') ->
                          (match Type.eq ty ty' with
                          | Some Eq -> check (v'::acc) vs
                          | None -> None)
                      | Object _ -> None)
                in
                check [] (v::vs)
            | Object _ -> None))
    | _ -> None
end

module Attribute = struct
  type t = string * Value.value
end

module Attributes = struct
  type t = Attribute.t list

  open Value
  let float n f = [n, Value (Value.float f)]
  let string n s = [n, Value (Value.string s)]
  let bool n b = [n, Value (Value.bool b)]
  let array n ty vs = [n, Value (Value.array ty vs)]

  let to_json xs =
    `O (List.map (fun (k, v) -> k, Value.to_json v) xs)

  let of_json j =
    let open Option in
    match j with
    | `O kvs ->
        Option.mapM (fun (k, v) ->
            let+ res = Value.of_json v in
            (k, res)) kvs
    | _ -> None
end

module Marker = struct
  open Attributes

  type t = Attribute.t list

  let color c = string "color" c
  let colors cs = array "color" Type.String cs

  let marker ats = List.concat ats

  let to_json = Attributes.to_json
  let of_json = Attributes.of_json
end
