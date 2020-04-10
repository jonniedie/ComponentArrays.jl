## Linear Algebra
Base.adjoint(x::CVector) = CArray(adjoint(_data(x)), Axis{1,NamedTuple()}(), _axes(x)[1])
Base.adjoint(x::CMatrix) = CArray(adjoint(_data(x)), reverse(_axes(x))...)

Base.transpose(x::CVector) = CArray(transpose(_data(x)), Axis{1,NamedTuple()}(), _axes(x)[1])
Base.transpose(x::CMatrix) = CArray(transpose(_data(x)), reverse(_axes(x))...)
