# Copyright (C) 2022 Heptazhou <zhou@0h7z.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""
	UUID4

The `UUID4` module provides universally unique identifier (UUID), version 4,
along with related functions.
"""
module UUID4

using Random: AbstractRNG
using Random: RandomDevice

export uuid
export uuid_parse
export uuid_string
export uuid_version

export UUID
const UUID = Base.UUID

"""
	uuid([rng::AbstractRNG]) -> UUID

Generates a version 4 (random or pseudo-random) universally unique identifier (UUID),
as specified by RFC 4122.

The default rng used by `uuid` is not `GLOBAL_RNG` and every invocation of `uuid()` without
an argument should be expected to return a unique identifier. Importantly, the outputs of
`uuid` do not repeat even when `Random.seed!(seed)` is called. Currently,
`uuid` uses `RandomDevice` as the default rng. However, this is an implementation
detail that may change in the future.

# Examples
```jldoctest
julia> using Random; rng = MersenneTwister(1234);

julia> uuid(rng)
UUID("7a052949-c101-4ca3-9a7e-43a2532b2fa8")
```
"""
function uuid(rng::AbstractRNG = RandomDevice())
	id = rand(rng, UInt128)
	id &= 0xffffffffffff0fff3fffffffffffffff
	id |= 0x00000000000040008000000000000000
	id |> UUID
end

"""
	uuid_parse(str::String; fmt::Int) -> Tuple{Int, UUID}
"""
function uuid_parse(str::String; fmt::Int = 0)::Tuple{Int, UUID}
	len = length(str)
	if 0 > fmt
		error("Invalid format `$fmt` (should be positive)")
	elseif len != fmt > 0
		error("Invalid id `$str` with length = $len (should be $fmt)")
	elseif len == 24
		len, uuid_parse(replace.(str, "-" => ""), fmt = 22)[2]
	elseif len == 29
		len, uuid_parse(replace.(str, "-" => ""), fmt = 25)[2]
	elseif len == 39
		len, uuid_parse(replace.(str, "-" => ""), fmt = 32)[2]
	elseif len == 22
		len, UUID(parse(UInt128, str, base = 62))
	elseif len == 25
		len, UUID(parse(UInt128, str, base = 36))
	elseif len == 32
		len, UUID(parse(UInt128, str, base = 16))
	elseif len == 36
		len, UUID(str)
	else
		error("Invalid id `$str` with length = $len")
	end
end

"""
	uuid_string(id::UUID = uuid()) -> Dict{Int, String}
"""
function uuid_string(id::UUID = uuid())::Dict{Int, String}
	id36 = string(id)
	id22 = string(id.value, base = 62, pad = 22)
	id25 = string(id.value, base = 36, pad = 25)
	id32 = string(id.value, base = 16, pad = 32)
	id24 = replace(id22, r"(.{7})" => s"\1-", count = 2)
	id29 = replace(id25, r"(.{5})" => s"\1-", count = 4)
	id39 = replace(id32, r"(.{4})" => s"\1-", count = 7)
	Dict(22 => id22, 24 => id24, 25 => id25, 29 => id29, 32 => id32, 36 => id36, 39 => id39)
end

"""
	uuid_version(id::String) -> Int
	uuid_version(id::UUID)   -> Int

Inspects the given UUID and returns its version
(see [RFC 4122](https://www.ietf.org/rfc/rfc4122)).

# Examples
```jldoctest
julia> uuid_version(uuid())
4
```
"""
function uuid_version end
uuid_version(id::String)::Int = uuid_parse(id)[2] |> uuid_version
uuid_version(id::UUID)::Int   = id.value >> 76 & 0xf |> Int

end # module

