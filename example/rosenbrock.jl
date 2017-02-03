function rosenbrock(x)
    f = (1 - x[1])^2 + 100*(x[2] - x[1]^2)^2

    g = zeros(2)
    g[1] = -2*(1 - x[1]) + 200*(x[2] - x[1]^2)*-2*x[1]
    g[2] = 200*(x[2] - x[1]^2)

    fail = false

    c = []
    dcdx = []

    return f, c, g, dcdx, fail

end


x0 = [4.0; 4.0]
lb = [-5.0; -5.0]
ub = [5.0; 5.0]
options = Dict{String, Any}()
options["Derivative option"] = 1
options["Verify level"] = 1
options["Major optimality tolerance"] = 1e-6

xopt, fopt, info = snopt(rosenbrock, x0, lb, ub, options)
println(xopt)
println(fopt)
println(info)
