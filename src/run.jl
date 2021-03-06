import Temporal.acf  # used for running autocorrelation function

using Statistics

"""
```
runmean(x::Array{T}; n::Int=10, cumulative::Bool=true)::Array{T}
runmean(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute a running or rolling arithmetic mean of an array.
"""
function runmean(x::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x,1))
    out[1:n-1] .= NaN
    if cumulative
        fi = 1.0:size(x,1)
        @inbounds for i in n:size(x,1)
            out[i] = sum(x[1:i])/fi[i]
        end
    else
        # original shorter but slower version of the code below
        # @inbounds for i = n:size(x,1)
        #     out[i] = mean(x[i-n+1:i])
        # end
        n_current = 0
        s::T = 0
        @inbounds for i = 1:n
            if isfinite(x[i])
                s += x[i]
                n_current += 1
            end
        end
        out[n] = n_current == n ? s / n : NaN
        @inbounds for i = n+1:size(x,1)
            if isfinite(x[i])
                s += x[i]
                n_current += 1
            end
            if isfinite(x[i-n])
                s -= x[i-n]
                n_current -= 1
            end
            out[i] = (n_current == n) ? s / n_current : NaN
        end
    end
    return out
end
runmean(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runmean(X[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...)

"""
```
runsum(x::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T}
runsum(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute a running or rolling summation of an array.
"""
function runsum(x::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    if cumulative
        out = cumsum(x, dims=1)
        out[1:n-1] .= NaN
    else
        out = zeros(size(x))
        out[1:n-1] .= NaN
        # original shorter but slower version of the code below
        # @inbounds for i = n:size(x,1)
        #     out[i] = sum(x[i-n+1:i])
        # end
        n_current = 0
        s::T = 0
        @inbounds for i = 1:n
            if isfinite(x[i])
                s += x[i]
                n_current += 1
            end
        end
        out[n] = n_current == n ? s : NaN
        @inbounds for i = n+1:size(x,1)
            if isfinite(x[i])
                s += x[i]
                n_current += 1
            end
            if isfinite(x[i-n])
                s -= x[i-n]
                n_current -= 1
            end
            out[i] = (n_current == n) ? s : NaN
        end
    end
    return out
end
runsum(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runsum(X[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...)

"""
```
runmad(x::Vector{T}; n::Int=10, cumulative::Bool=true, fun::Function=median)::Vector{T}
runmad(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute the running or rolling mean absolute deviation of an array
"""
function runmad(x::Vector{T}; n::Int=10, cumulative::Bool=true, fun::Function=median)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x))
    out[1:n-1] .= NaN
    center = 0.0
    if cumulative
        fi = collect(1.0:size(x,1))
        @inbounds for i = n:size(x,1)
            center = fun(x[1:i])
            out[i] = sum(abs.(x[1:i].-center)) / fi[i]
        end
    else
        fn = float(n)
        @inbounds for i = n:size(x,1)
            center = fun(x[i-n+1:i])
            out[i] = sum(abs.(x[i-n+1:i].-center)) / fn
        end
    end
    return out
end
runmad(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runmad(X[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...)

"""
```
runvar(x::Vector{T}; n::Int=10, cumulative=true)::Vector{T}
runvar(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute the running or rolling variance of an array
"""
function runvar(x::Vector{T}; n::Int=10, cumulative=true)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x))
    out[1:n-1] .= NaN
    if cumulative
        @inbounds for i = n:size(x,1)
            out[i] = var(x[1:i])
        end
    else
        @inbounds for i = n:size(x,1)
            out[i] = var(x[i-n+1:i])
        end
    end
    return out
end
runvar(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runvar(X[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...)

"""
```
runsd(x::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T}
runsd(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute the running or rolling standard deviation of an array
"""
function runsd(x::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T} where {T<:AbstractFloat}
    return sqrt.(runvar(x, n=n, cumulative=cumulative))
end
runsd(X::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = sqrt.(hcat((runvar(X[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...))

"""
```
runcov(x::Vector{T}, y::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T}
runcov(X::Matrix, Y::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute the running or rolling covariance of two arrays
"""
function runcov(x::Vector{T}, y::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T} where {T<:AbstractFloat}
    @assert length(x) == length(y) "Dimension mismatch: length of `x` not equal to length of `y`."
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x))
    out[1:n-1] .= NaN
    if cumulative
        @inbounds for i = n:length(x)
            out[i] = cov(x[1:i], y[1:i])
        end
    else
        @inbounds for i = n:length(x)
            out[i] = cov(x[i-n+1:i], y[i-n+1:i])
        end
    end
    return out
end
runcov(X::Matrix, Y::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runcov(X[:,j], Y[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...)

"""
```
runcor(x::Vector{T}, y::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T}
runcor(X::Matrix, y::Vector; n::Int=10, cumulative::Bool=true)::Matrix
runcor(X::Matrix, Y::Matrix; n::Int=10, cumulative::Bool=true)::Matrix
```

Compute the running or rolling correlation of two arrays
"""
function runcor(x::Vector{T}, y::Vector{T}; n::Int=10, cumulative::Bool=true)::Vector{T} where {T<:Float64}
    @assert length(x) == length(y) "Dimension mismatch: length of `x` not equal to length of `y`."
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x))
    out[1:n-1] .= NaN
    if cumulative
        @inbounds for i = n:length(x)
            out[i] = cor(x[1:i], y[1:i])
        end
    else
        @inbounds for i = n:length(x)
            out[i] = cor(x[i-n+1:i], y[i-n+1:i])
        end
    end
    return out
end
runcor(X::Matrix, Y::Matrix; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runcor(X[:,j], Y[:,j], n=n, cumulative=cumulative) for j in 1:size(X,2))...)
runcor(X::Matrix, y::Vector; n::Int=10, cumulative::Bool=true)::Matrix = hcat((runcor(X[:,j], y, n=n, cumulative=cumulative) for j in 1:size(X,2))...)

"""
```
runmax(x::Vector{T}; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Vector{T}
runmax(X::Matrix; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Matrix
```

Compute the running or rolling maximum of an array
"""
function runmax(x::Vector{T}; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x))
    if inclusive
        if cumulative
            out[n] = maximum(x[1:n])
            @inbounds for i = n+1:size(x,1)
                out[i] = max(out[i-1], x[i])
            end
        else
            @inbounds for i = n:size(x,1)
                out[i] = maximum(x[i-n+1:i])
            end
        end
        out[1:n-1] .= NaN
        return out
    else
        if cumulative
            out[n+1] = maximum(x[1:n])
            @inbounds for i = n+1:size(x,1)-1
                out[i+1] = max(out[i-1], x[i-1])
            end
        else
            @inbounds for i = n:size(x,1)-1
                out[i+1] = maximum(x[i-n+1:i])
            end
        end
        out[1:n] .= NaN
        return out
    end
end
runmax(X::Matrix; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Matrix = hcat((runmax(X[:,j], n=n, cumulative=cumulative, inclusive=inclusive) for j in 1:size(X,2))...)

"""
```
runmin(x::Vector{T}; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Vector{T}
runmin(X::Matrix; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Matrix
```

Compute the running or rolling minimum of an array
"""
function runmin(x::Vector{T}; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(size(x))
    if inclusive
        if cumulative
            out[n] = minimum(x[1:n])
            @inbounds for i = n+1:size(x,1)
                out[i] = min(out[i-1], x[i])
            end
        else
            @inbounds for i = n:size(x,1)
                out[i] = minimum(x[i-n+1:i])
            end
        end
        out[1:n-1] .= NaN
        return out
    else
        if cumulative
            out[n+1] = minimum(x[1:n])
            @inbounds for i = n+1:size(x,1)-1
                out[i+1] = min(out[i-1], x[i-1])
            end
        else
            @inbounds for i = n:size(x,1)-1
                out[i+1] = minimum(x[i-n+1:i])
            end
        end
        out[1:n] .= NaN
        return out
    end
end
runmin(X::Matrix; n::Int=10, cumulative::Bool=true, inclusive::Bool=true)::Matrix = hcat((runmin(X[:,j], n=n, cumulative=cumulative, inclusive=inclusive) for j in 1:size(X,2))...)

"""
```
runquantile(x::Vector{T}; p::T=0.05, n::Int=10, cumulative::Bool=true)::Vector{T}
runquantile(X::Matrix; n::Int=10, cumulative::Bool=true, p::Real=0.05)::Matrix
```

Compute the running/rolling quantile of an array
"""
function runquantile(x::Vector{T}; p::T=0.05, n::Int=10, cumulative::Bool=true)::Vector{T} where {T<:AbstractFloat}
    @assert n<size(x,1) && n>1 "Argument n is out of bounds."
    out = zeros(T, size(x,1))
    if cumulative
        @inbounds for i in 2:size(x,1)
            out[i] = quantile(x[1:i], p)
        end
        out[1] = NaN
    else
        @inbounds for i in n:size(x,1)
            out[i] = quantile(x[i-n+1:i], p)
        end
        out[1:n-1] .= NaN
    end
    return out
end
runquantile(X::Matrix; n::Int=10, cumulative::Bool=true, p::Real=0.05)::Matrix = hcat((runquantile(X[:,j], n=n, cumulative=cumulative, p=p) for j in 1:size(X,2))...)

"""
```
function runacf(x::Vector{T};
                n::Int = 10,
                maxlag::Int = n-3,
                lags::AbstractVector{Int,1} = 0:maxlag,
                cumulative::Bool = true)::Matrix{T} where {T<:AbstractFloat}
runacf(X::Matrix; n::Int=10, cumulative::Bool=true, maxlag::Int=n-3, lags::AbstractVector{Int}=0:maxlag)::Matrix
```

Compute the running/rolling autocorrelation of a vector.
"""
function runacf(x::Vector{T};
                n::Int = 10,
                maxlag::Int = n-3,
                lags::AbstractVector{Int} = 0:maxlag,
                cumulative::Bool = true)::Matrix{T} where {T<:AbstractFloat}
    @assert size(x, 2) == 1 "Autocorrelation input array must be one-dimensional"
    N = size(x, 1)
    @assert n < N && n > 0
    if length(lags) == 1 && lags[1] == 0
        return ones((N, 1))
    end
    out = zeros((N, length(lags))) * NaN
    if cumulative
        @inbounds for i in n:N
            out[i,:] = acf(x[1:i], lags=lags)
        end
    else
        @inbounds for i in n:N
            out[i,:] = acf(x[i-n+1:i], lags=lags)
        end
    end
    return out
end
runacf(X::Matrix; n::Int=10, cumulative::Bool=true, maxlag::Int=n-3, lags::AbstractVector{Int}=0:maxlag)::Matrix = hcat((runacf(X[:,j], n=n, cumulative=cumulative, maxlag=maxlag, lags=lags) for j in 1:size(X,2))...)

"""
```
runfun(x::Vector{T}, f::Function; n::Int = 10, cumulative::Bool=false, args...)::Vector{T} where {T<:AbstractFloat}
runfun(X::Matrix{T}, f::Function; n::Int=10, cumulative::Bool=false, args...)::Matrix{T} where {T<:AbstractFloat}
```

Apply a general function `f` that returns a scalar over an array
"""
function runfun(x::Vector{T}, f::Function; n::Int = 10, cumulative::Bool=false, args...)::Vector{T} where {T<:AbstractFloat}
    N = size(x,1)
    out = zeros(T, N) .* NaN
    if cumulative
        for i in n:N
            result::T = f(x[1:i]; args...)
            out[i] = result
        end
    else
        for i in n:N
            result::T = f(x[i-n+1:i]; args...)
            out[i] = result
        end
    end
    return out
end

function runfun(X::Matrix{T}, f::Function; n::Int=10, cumulative::Bool=false, args...)::Matrix{T} where {T<:AbstractFloat}
    return hcat((runfun(X[:,j], f, n=n, cumulative=cumulative; args...) for j in 1:size(X,2))...)
end
