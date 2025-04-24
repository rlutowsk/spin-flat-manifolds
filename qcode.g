ElementFromWordVector := function( gens, vec )
    local e, i, x;
    x := One(gens[1]);
    for e in vec do
        i := AbsInt(e);
        if e < 0 then
            x := x * gens[i]^-1;
        elif e > 0 then
            x := x * gens[i];
        fi;
    od;
    return x;
end;

SpinExtensionByMat := function( mat )
    local n, g, p, f, nc;

    n := Maximum( List(mat, Maximum) );
    nc:= NrCols( mat );
    if ForAll(mat, row->row[nc]=0) then
        n := n+1;
    fi;
    g := FreeGroup( n );
    f := GeneratorsOfGroup( g );
    p := List( [1..n-1], i->Comm(f[i], f[n]) );
    Add( p, f[n]^2 );
    Append( p, List( mat, row->ElementFromWordVector(f, row) ) );
    return g/p;
end;

QData := function(r)
    local egens;
    
    egens := ShallowCopy( r.generators );
    Add( egens, One(r.generators[1]) );

    r.orientable  := ForAll( r.generators, x->Determinant(x)=1 );
    r.point_group := Group( r.generators );
    r.spin_group  := SpinExtensionByMat( r.presentation );
    r.size        := Size( r.point_group );
    r.lambda      := GroupHomomorphismByImages( r.spin_group, r.point_group, GeneratorsOfGroup( r.spin_group ), egens );
end;

FillQData := function(list, v...)
    local log, r;

    if Size(v)=0 or v[1]<>true then
        log := function(v...) end;
    else
        log := Print;
    fi;
    for r in list do
        log("calculating ", r.name, " ... \c");
        QData(r);
        log("done\n");
        if r.lambda = fail then
            Error("Covering homomorphism not calculated");
        fi;
    od;
end;

WriteQData := function(list, dirname)
    local r, n, m;

    for r in list do
        CaratWriteBravaisFile( Concatenation( dirname, "/", r.name ), r );
        n := NrCols( r.presentation )-1;
        m := NrRows( r.presentation );
        CaratWriteMatrixFile( Concatenation( dirname, "/pres.", r.name ), r.presentation{[1..m]}{[1..n]} );
    od;
end;