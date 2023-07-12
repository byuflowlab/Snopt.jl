using Snopt
using SparseArrays
using Infiltrator

# ---- unconstrained, no dervatives provided. -----

function matyas(g, df, dg, x, deriv)
    f = 0.26 * (x[1]^2 + x[2]^2) - 0.48 * x[1] * x[2]
    fail = false
    return f, fail
end
x0 = [5.0; 7]
lx = [-10.0; -10]
ux = [10.0; 10]
lg = []
ug = []
rows = []
cols = [] 
options = Dict(
    "Derivative option" => 0
)
xopt, fopt, info, out = snsolve(matyas, x0, lx, ux, lg, ug, rows, cols, options)


# ---- unconstrained, providing gradient -----

function rosenbrock(g, df, dg, x, deriv)
    f = (1 - x[1])^2 + 100*(x[2] - x[1]^2)^2
    fail = false

    if deriv
        df[1] = -2*(1 - x[1]) + 200*(x[2] - x[1]^2)*-2*x[1]
        df[2] = 200*(x[2] - x[1]^2)
    end

    return f, fail
end


x0 = [4.0; 4.0]
lx = [-5.0; -5.0]
ux = [5.0; 5.0]
lg = []
ug = []
rows = []
cols = []

xopt, fopt, info, out = snsolve(rosenbrock, x0, lx, ux, lg, ug, rows, cols)


# --------- constrained, not providing derivatives ------

function barnes(g, df, dg, x, deriv)

    a1 = 75.196
    a3 = 0.12694
    a5 = 1.0345e-5
    a7 = 0.030234
    a9 = 3.5256e-5
    a11 = 0.25645
    a13 = 1.3514e-5
    a15 = -5.2375e-6
    a17 = 7.0e-10
    a19 = -1.6638e-6
    a21 = 0.0005
    a2 = -3.8112
    a4 = -2.0567e-3
    a6 = -6.8306
    a8 = -1.28134e-3
    a10 = -2.266e-7
    a12 = -3.4604e-3
    a14 = -28.106
    a16 = -6.3e-8
    a18 = 3.4054e-4
    a20 = -2.8673

    x1 = x[1]
    x2 = x[2]
    y1 = x1*x2
    y2 = y1*x1
    y3 = x2^2
    y4 = x1^2

    # --- function value ---

    f = a1 + a2*x1 + a3*y4 + a4*y4*x1 + a5*y4^2 +
        a6*x2 + a7*y1 + a8*x1*y1 + a9*y1*y4 + a10*y2*y4 +
        a11*y3 + a12*x2*y3 + a13*y3^2 + a14/(x2+1) +
        a15*y3*y4 + a16*y1*y4*x2 + a17*y1*y3*y4 + a18*x1*y3 +
        a19*y1*y3 + a20*exp(a21*y1)
    fail = false

    # --- constraints ---

    g[1] = 1 - y1/700.0
    g[2] = y4/25.0^2 - x2/5.0
    g[3] = (x1/500.0- 0.11) - (x2/50.0-1)^2

    return f, fail

end


x0 = [10.0; 10.0]
lx = [0.0; 0.0]
ux = [65.0; 70.0]
lg = -Inf*ones(3)
ug = zeros(3)
rows = [1, 2, 3, 1, 2, 3]
cols = [1, 1, 1, 2, 2, 2]
options = Dict(
    "Derivative option" => 0
)

xopt, fopt, info, out = snsolve(barnes, x0, lx, ux, lg, ug, rows, cols, options)



# ----- constrained, providing derivatives (dense jacobian) ---------


function barnesgrad(g, df, dg, x, deriv)

    a1 = 75.196
    a3 = 0.12694
    a5 = 1.0345e-5
    a7 = 0.030234
    a9 = 3.5256e-5
    a11 = 0.25645
    a13 = 1.3514e-5
    a15 = -5.2375e-6
    a17 = 7.0e-10
    a19 = -1.6638e-6
    a21 = 0.0005
    a2 = -3.8112
    a4 = -2.0567e-3
    a6 = -6.8306
    a8 = -1.28134e-3
    a10 = -2.266e-7
    a12 = -3.4604e-3
    a14 = -28.106
    a16 = -6.3e-8
    a18 = 3.4054e-4
    a20 = -2.8673

    x1 = x[1]
    x2 = x[2]
    y1 = x1*x2
    y2 = y1*x1
    y3 = x2^2
    y4 = x1^2

    # --- function value ---

    f = a1 + a2*x1 + a3*y4 + a4*y4*x1 + a5*y4^2 +
        a6*x2 + a7*y1 + a8*x1*y1 + a9*y1*y4 + a10*y2*y4 +
        a11*y3 + a12*x2*y3 + a13*y3^2 + a14/(x2+1) +
        a15*y3*y4 + a16*y1*y4*x2 + a17*y1*y3*y4 + a18*x1*y3 +
        a19*y1*y3 + a20*exp(a21*y1)
    fail = false

    # --- constraints ---

    g[1] = 1 - y1/700.0
    g[2] = y4/25.0^2 - x2/5.0
    g[3] = (x1/500.0- 0.11) - (x2/50.0-1)^2

    if deriv
        # --- derivatives of f ---

        dy1 = x2
        dy2 = y1 + x1*dy1
        dy4 = 2*x1
        dfdx1 = a2 + a3*dy4 + a4*y4 + a4*x1*dy4 + a5*2*y4*dy4 +
            a7*dy1 + a8*y1 + a8*x1*dy1 + a9*y1*dy4 + a9*y4*dy1 + a10*y2*dy4 + a10*y4*dy2 +
            a15*y3*dy4 + a16*x2*y1*dy4 + a16*x2*y4*dy1 + a17*y3*y1*dy4 + a17*y3*y4*dy1 + a18*y3 +
            a19*y3*dy1 + a20*exp(a21*y1)*a21*dy1

        dy1 = x1
        dy2 = x1*dy1
        dy3 = 2*x2
        dfdx2 = a6 + a7*dy1 + a8*x1*dy1 + a9*y4*dy1 + a10*y4*dy2 +
            a11*dy3 + a12*x2*dy3 + a12*y3 + a13*2*y3*dy3 + a14*-1/(x2+1)^2 +
            a15*y4*dy3 + a16*y4*y1 + a16*y4*x2*dy1 + a17*y4*y1*dy3 + a17*y4*y3*dy1 + a18*x1*dy3 +
            a19*y3*dy1 + a19*y1*dy3 + a20*exp(a21*y1)*a21*dy1

        df[1] = dfdx1
        df[2] = dfdx2

        # --- derivatives of g ---

        dg[1] = -x2/700.0  # 1, 1
        dg[2] = 2*x1/25^2   # 2, 1
        dg[3] = 1.0/500  # 3, 1
        dg[4] = -x1/700.0  # 1, 2
        dg[5] = -1.0/5   # 2, 2
        dg[6] = -2*(x2/50.0-1)/50.0  # 3, 2
    end

    return f, fail
end



x0 = [10.0; 10.0]
lx = [0.0; 0.0]
ux = [65.0; 70.0]
lg = -Inf*ones(3)
ug = zeros(3)
rows = [1, 2, 3, 1, 2, 3]
cols = [1, 1, 1, 2, 2, 2]
options = Dict(
    "Verify level" => 1
)

xopt, fopt, info, out = snsolve(barnesgrad, x0, lx, ux, lg, ug, rows, cols, options)


# ----- constrained, providing derivatives (sparse jacobian) ---------

function sparsegrad(g, df, dg, x, deriv)

    f = x[1]^2 - x[2]
    fail = false

    # --- constraints ---

    g[1] = x[2] - 2*x[1]
    g[2] = -x[2]

    # --- derivatives of f ---

    df[1] = 2*x[1]
    df[2] = -1.0

    # --- derivatives of g ---

    dg[1] = -2.0  # 1, 1
    dg[2] = 1.0  # 1, 2
    dg[3] = -1.0   # 2, 2

    return f, fail

end

x0 = [0.0; 0.0]
lx = [-10.0, -10.0]
ux = [10.0, 10.0]
lg = -Inf*ones(2)
ug = zeros(2)
rows = [1, 1, 2]
cols = [1, 2, 2]
options = Dict(
    "Verify level" => 1
)


xopt, fopt, info, out = snsolve(sparsegrad, x0, lx, ux, lg, ug, rows, cols, options)


# ------- adding names in output file ------

x0 = [12.0; 10.0]
lx = [0.0; 0.0]
ux = [65.0; 70.0]
lg = -Inf*ones(3)
ug = zeros(3)

rows = [1, 2, 3, 1, 2, 3]
cols = [1, 1, 1, 2, 2, 2]
names = Snopt.Names("howdy", ["x1", "x2"], ["obj", "g1", "g2", "g3"])
xopt, fopt, info, out = snsolve(barnesgrad, x0, lx, ux, lg, ug, rows, cols, names=names) 


# -------- warm start --------------

x0 = [12.0; 10.0]
lx = [0.0; 0.0]
ux = [65.0; 70.0]
lg = -Inf*ones(3)
ug = zeros(3)
rows = [1, 2, 3, 1, 2, 3]
cols = [1, 1, 1, 2, 2, 2]

# artificially limiting the major iterations so we can restart
options = Dict(
    "Major iterations limit" => 15
)


xopt, fopt, info, out = snsolve(barnesgrad, x0, lx, ux, lg, ug, rows, cols, options) 
println("major iter = ", out.major_iter)

# warm start from where we stopped
warmstart = out.warm  # a WarmStart type
xopt, fopt, info, out = snsolve(barnesgrad, warmstart, lx, ux, lg, ug, rows, cols) 
println("major iter = ", out.major_iter)


# -------- linear functions --------------


function lp(g, df, dg, x, deriv)
    f = 0.0  # no nonlinear component
    g .= 0.0
    df .= 0.0
    fail = false

    return f, fail
end

x0 = ones(10)
lx = zeros(10)
ux = 4*ones(10)
lg = [5.0, 7, 1]
ug = [8.0, Inf, 10.0] 
rows = []
cols = []

A = [
    0.46 0.54 0.40 0.39 0.49 0.03 0.66 0.26 0.05 0.60  # obj
    0.56 0.84 0.23 0.48 0.05 0.69 0.87 0.85 0.88 0.62  # constraint 1
    0.29 0.98 0.36 0.14 0.26 0.41 0.87 0.97 0.13 0.69  # constraint 2
    0.48 0.55 0.78 0.59 0.79 0.84 0.01 0.77 0.13 0.10  # constraint 3
]

xopt, fopt, info, out = snsolve(lp, x0, lx, ux, lg, ug, rows, cols, A=A)

function barnesgrad_snopta(f, dg, x, deriv)

    a1 = 75.196
    a3 = 0.12694
    a5 = 1.0345e-5
    a7 = 0.030234
    a9 = 3.5256e-5
    a11 = 0.25645
    a13 = 1.3514e-5
    a15 = -5.2375e-6
    a17 = 7.0e-10
    a19 = -1.6638e-6
    a21 = 0.0005
    a2 = -3.8112
    a4 = -2.0567e-3
    a6 = -6.8306
    a8 = -1.28134e-3
    a10 = -2.266e-7
    a12 = -3.4604e-3
    a14 = -28.106
    a16 = -6.3e-8
    a18 = 3.4054e-4
    a20 = -2.8673

    x1 = x[1]
    x2 = x[2]
    y1 = x1*x2
    y2 = y1*x1
    y3 = x2^2
    y4 = x1^2

    # --- function value ---
    f[1] = a1 + a2*x1 + a3*y4 + a4*y4*x1 + a5*y4^2 +
           a6*x2 + a7*y1 + a8*x1*y1 + a9*y1*y4 + a10*y2*y4 +
           a11*y3 + a12*x2*y3 + a13*y3^2 + a14/(x2+1) +
           a15*y3*y4 + a16*y1*y4*x2 + a17*y1*y3*y4 + a18*x1*y3 +
           a19*y1*y3 + a20*exp(a21*y1)

    # --- constraints ---
    f[2] = 1 - y1/700.0
    f[3] = y4/25.0^2 - x2/5.0
    f[4] = (x1/500.0- 0.11) - (x2/50.0-1)^2

    if deriv
        dy1 = x2
        dy2 = y1 + x1*dy1
        dy4 = 2*x1
        dfdx1 = a2 + a3*dy4 + a4*y4 + a4*x1*dy4 + a5*2*y4*dy4 +
            a7*dy1 + a8*y1 + a8*x1*dy1 + a9*y1*dy4 + a9*y4*dy1 + a10*y2*dy4 + a10*y4*dy2 +
            a15*y3*dy4 + a16*x2*y1*dy4 + a16*x2*y4*dy1 + a17*y3*y1*dy4 + a17*y3*y4*dy1 + a18*y3 +
            a19*y3*dy1 + a20*exp(a21*y1)*a21*dy1

        dy1 = x1
        dy2 = x1*dy1
        dy3 = 2*x2
        dfdx2 = a6 + a7*dy1 + a8*x1*dy1 + a9*y4*dy1 + a10*y4*dy2 +
            a11*dy3 + a12*x2*dy3 + a12*y3 + a13*2*y3*dy3 + a14*-1/(x2+1)^2 +
            a15*y4*dy3 + a16*y4*y1 + a16*y4*x2*dy1 + a17*y4*y1*dy3 + a17*y4*y3*dy1 + a18*x1*dy3 +
            a19*y3*dy1 + a19*y1*dy3 + a20*exp(a21*y1)*a21*dy1

        dg[1] = dfdx1       # 1, 1
        dg[2] = -x2/700.0   # 2, 1
        dg[3] = 2*x1/25^2   # 3, 1
        dg[4] = 1.0/500     # 4, 1
        dg[5] = dfdx2       # 1, 2
        dg[6] = -x1/700.0   # 2, 2 
        dg[7] = -1.0/5      # 3, 2
        dg[8] = -2*(x2/50.0-1)/50.0 # 4, 2
    end
    return false
end

x0      = [10.0; 10.0]
start   = Snopt.ColdStart(x0, 4)
ObjAdd  = 0.0
ObjRow  = 1
iAfun   = Int32[1]
jAvar   = Int32[1]
A       = [0.0]
iGfun   = [1, 2, 3, 4, 1, 2, 3, 4]
jGvar   = [1, 1, 1, 1, 2, 2, 2, 2]
lx      = [0.0; 0.0]
ux      = [65.0; 70.0]
lg      = -Inf*ones(4)
ug      = [Inf, 0.0, 0.0, 0.0]
options = Dict(
    "Verify level" => 1
)

xopt, fopt, info, out = snopta(barnesgrad_snopta, start, ObjAdd, ObjRow, iAfun, jAvar, A,
                            iGfun, jGvar, lx, ux, lg, ug, options)
