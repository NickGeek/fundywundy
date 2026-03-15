module Cents : sig
  type t = int64
  val (+) : t -> t -> t
  val (-) : t -> t -> t
  val ( * ) : t -> t -> t
  val (/) : t -> t -> t
  val to_string : t -> string
  val from_float : float -> t
end

module BasisPoints : sig
  type t = int64
  val (+) : t -> t -> t
  val (-) : t -> t -> t
  val ( * ) : t -> t -> t
  val (/) : t -> t -> t
  val percentage_of : t -> int64 -> int64
  val from_float : float -> t
end

module FundMap : sig
  include Map.S with type key = string
  val length : 'a t -> int
  val update_any : (key -> 'a -> 'a) -> 'a t -> 'a t
end

type balances = Cents.t FundMap.t
type fund_targets = BasisPoints.t FundMap.t
type order_mode = Buy | Sell

val balances_to_string : balances -> string
val calculate_orders : balances -> int64 -> fund_targets -> order_mode -> balances
