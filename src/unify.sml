structure Unify = struct
  open Utils
  structure L = List
  structure S = String
  structure C = Color

  type     vname = string * int
  datatype term  = V of vname | $ of string * term list
  infix 3 $

  type     subst = (vname * term) list

  val bright = fn c => C.format (C.Bright, c)

  fun toString (V (s, i)) =
        C.format (C.Bright, C.Cyan) (s ^ "@" ^ Int.toString i)
    | toString (c $ []) = C.format (C.Bright, C.Magenta) c
    | toString (f $ ts) =
        (C.format (C.Bright, C.Green) f)
        ^ bright C.White "("
          ^ intercalate ", " (List.map toString ts)
        ^ bright C.White ")"

  fun indom x s = List.exists (fn (y, _) => x = y) s

  fun app ((y, t)::s) x = if x = y then t else app s x

  fun lift s (V x) = if indom x s then app s x else V x
    | lift s (f $ ts) = f $ (L.map (lift s) ts)

  fun occurs x (V y) = x = y
    | occurs x (_ $ ts) = List.exists (occurs x) ts

  exception NoUnifier

  fun solve ([], s) = s
    | solve ((V x, t)::S, s) =
        if V x = t then solve (S, s) else elim (x, t, S, s)
    | solve ((t, V x)::S, s) = elim (x, t, S, s)
    | solve ((f $ ts, g $ us)::S, s) =
        case String.compare (f, g) of
          EQUAL => solve (zip (ts, us) @ S, s)
        | _ => raise NoUnifier

  and elim (x, t, S, s)   =
    if occurs x t
    then raise NoUnifier
    else
      let val xt = lift [(x, t)]
      in
        solve (L.map (fn (t1, t2) => (xt t1, xt t2)) S,
               (x, t)::(L.map (fn (y, u) => (y, xt u)) s))
      end

  fun unify (t1, t2) = solve ([(t1, t2)], [])

end
