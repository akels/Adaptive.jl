__precompile__() # this module is safe to precompile
module Adaptive

using PyPlot
import PyPlot: plot

using PyCall
const adaptive = PyNULL()

function __init__()
    #copy!(adaptive, pyimport_conda("adaptive", "adaptive"))
    copy!(adaptive, pyimport_conda("adaptive", "adaptive", "conda-forge"))
end

import Base.getproperty

import TaskMaster: Learner, ask!, tell! 

abstract type AdaptiveLearner <: Learner end
ask!(learner::AdaptiveLearner,input) = learner.learner.ask(1)[1][1] ### Need to make ask! accept a state.
tell!(learner::AdaptiveLearner,(xi,yi)) = learner.learner.tell(xi,yi)

######### 1D #########

struct AdaptiveLearner1D <: AdaptiveLearner
    learner
end
AdaptiveLearner1D(box::Tuple{Number,Number}) = AdaptiveLearner1D(adaptive.Learner1D(x->NaN,box))

function Base.getproperty(l::AdaptiveLearner1D,s::Symbol)
    learner = getfield(l,:learner)

    if s==:x
        d = [(key,value) for (key,value) in learner.data]
        x = Float64[i[1] for i in d]
        sort(x)
    elseif s==:y
        d = [(key,value) for (key,value) in learner.data]
        x = Float64[i[1] for i in d]
        y = Float64[i[2] for i in d]
        y[sortperm(x)]
    elseif s==:data
        learner.data
    elseif s==:pending_points
        Set(p for p in learner.pending_points)        
    elseif s==:learner
        learner
    else
        getproperty(learner,s)
    end
end

########## 2D #############

struct AdaptiveLearner2D <: AdaptiveLearner
    learner
    AdaptiveLearner2D(box) = new(adaptive.Learner2D(x->NaN,box))
end

function Base.getproperty(l::AdaptiveLearner2D,s::Symbol)
    learner = getfield(l,:learner)

    if s==:points
        tri = learner.ip().tri
        tri.points
    elseif s==:vertices
        tri = learner.ip().tri
        tri.vertices .+ 1
    elseif s==:pending_points
        Set(p for p in learner.pending_points)        
    elseif s==:values
        [v for v in py"$(learner).data.values()"]
    elseif s==:learner
        learner
    else
        getproperty(learner,s)
    end
end

### ToDo
# - Add more options
# - Think of way to make Adaptive independent of Plots. RecipesBase? Or optional dependencies.
function plot(learner2d::AdaptiveLearner2D)
    p,tri,v = learner2d.points, learner2d.vertices, learner2d.values
    tricontourf(p[:,1],p[:,2],tri.-1,v)
    triplot(p[:,1],p[:,2],tri.-1,"k.-")
end

export AdaptiveLearner1D, AdaptiveLearner2D, ask!, tell!, plot

end 
