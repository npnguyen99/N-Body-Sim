module Tree_lib

using Vec_lib
using Bod_lib
export Tree, isLeaf, isEmpty, push, apply

mutable struct Tree{T <: Vec}
    origin::T
    size::Float64
    children::Vector{Tree{T}}
    center::Union{Body{T}, Nothing}
end

isLeaf(tree::Tree)::Bool = length(tree.children) == 0
isEmpty(tree::Tree)::Bool = tree.center == nothing

function push(tree::Tree{T}, a::Body{T}) where {T}
    if isLeaf(tree)
        if isEmpty(tree)
            tree.center = a
        else
            b = tree.center
            tree.center = a + b
            tree.children::Vector{Tree{T}} = spawnChildren(tree.origin, tree.size)
            middle::T = tree.children[1].origin
            push(tree.children[quadrant(a.pos - middle)], a)
            push(tree.children[quadrant(b.pos - middle)], b)
        end
    else
        middle = tree.children[1].origin
        add(tree.center, a)
        push(tree.children[quadrant(a.pos - middle)], a)
    end
end

function spawnChildren(o::Vec2d, s::Float64)::Vector{Tree{Vec2d}}
    sp = 0.5s
    children::Vector{Tree{Vec2d}} = [
    Tree(Vec2d(o.x + sp, o.y + sp), sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(Vec2d(o.x, o.y + sp), sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(o, sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(Vec2d(o.x + sp, o.y), sp, Vector{Tree{Vec2d}}(), nothing)
    ]
    children
end

function spawnChildren(o::Vec3d, s::Float64)::Vector{Tree{Vec3d}}
    sp = 0.5s
    children::Vector{Tree{Vec3d}} = [
    Tree(Vec3d(o.x + sp, o.y + sp, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x, o.y + sp, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x, o.y, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x + sp, o.y, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x + sp, o.y + sp, o.z), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x, o.y + sp, o.z), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(o, sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x + sp, o.y, o.z), sp, Vector{Tree{Vec3d}}(), nothing)
    ]
    children
end

function updateAcc(a::Body{T}, b::Body{T}, G::Float64) where {T}
    e = 0.5(radius(a) + radius(b))
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    add(a.acc, -(G * b.mass / ((rlensqr + e^2)^1.5) * r))
end

function updateAccL(a::Body{T}, b::Body{T}, G::Float64, dt::Float64) where {T}
    e = 0.5(radius(a) + radius(b))
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    add(a.acc, -(G * b.mass / ((rlensqr + e^2)^1.5) * r))

    rad = 2e
    rlen = sqrt(rlensqr)
    dr = rlen - rad

    if dr > 0.01 && dr < 0.011
        dp = (a.mass * a.vel)
        add(dp, -b.mass * b.vel)
        mul(dp, -5e-4 * 30 / dt / a.mass)
        add(a.acc, dp)
    end

    if dr <= 0
        rhat = r / rlen
        f = -5 * 10000dr / a.mass
        add(a.acc, f * rhat)

        dp = -(a.mass * dot(a.vel, rhat) - b.mass * dot(b.vel, rhat)) / a.mass / dt
        dp *= 5e-4 * 1000
        mul(rhat, dp)
        add(a.acc, rhat)
    end
end

function apply(a::Body{T}, tree::Tree{T}, theta::Float64, G::Float64, dt::Float64) where {T}
    if isEmpty(tree)
        return
    end
    if isLeaf(tree)
        if a.tag != tree.center.tag
            # updateAccL(a, tree.center, G, dt)
            updateAccGas(a, tree.center)
        end
    else
        if tree.size / dist(tree.center.pos, a.pos) < theta
            # updateAcc(a, tree.center, G)
        else
            for i in tree.children
                apply(a, i, theta, G, dt)
            end
        end
    end
end

end