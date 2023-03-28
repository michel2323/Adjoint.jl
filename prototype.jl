using Base.Experimental: @opaque

mutable struct Independent
    value::Float64
    adjoint::Float64
    func::Function
end

function Independent(x::Float64)
    d = Independent(
            x,
            0.0,
            _ -> nothing
        )
    d.func = @opaque (adjoint) -> begin adjoint
                d.adjoint += adjoint
                return nothing
            end
    return d
end

mutable struct Dual
    value::Float64
    func::Function
end

function Dual(x::Float64)
    d = Dual(
            x,
            x -> x
        )
    d.func = @opaque (adjoint) -> begin adjoint
            println("adj: $adjoint, $(d.value)")
                return nothing
            end
    return d
end

Base.zero(::Type{Dual}) = Dual(0.0)

# Unary function
g(x) = Dual(
    sin(x.value),
    @opaque (adjoint) -> begin
        return x.func(cos(x.value) * adjoint)
    end
)

# Binary function
f(x, y) = Dual(
    x.value * y.value,
    @opaque (adjoint) -> begin
            x.func(adjoint * y.value)
            y.func(adjoint * x.value)
            return nothing
    end
)

x = Independent(2.0)
y = Independent(3.0)
z = g(f(x, y))
z.func(1.0)
println("[Adjoints] dz/dx: $(indepx.adjoint), dz/dy: $(indepy.adjoint)")

# Trying aliasing
x = Independent(2.0)
refx = Ref(x)
y = Independent(3.0)
x = f(x, y)
x = f(x, y)
x.func(1.0)
println("[Adjoints] dz/drefx: $(refx[].adjoint)")

