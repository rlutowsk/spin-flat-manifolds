ReadAffData := function(list, dirname)
    local r;
    for r in list do
        r.generators := CaratReadMatrixFile( Concatenation(dirname, "/", r.name) );
        r.dim := Size( r.generators[1] ) - 1;
    od;
end;

CheckRelations2 := function( sgens, img )
    local dim, s, g, vec;

    dim := Size( sgens[1] ) - 1;
    vec := img{[Size(sgens)+1..Size(img)]};
    for s in sgens do
        g := s{[1..dim]}{[1..dim]};
        if ForAny([1..dim], i->Product([1..dim], k->vec[k]^g[k,i])<>vec[i]) then
            return false;
        fi;
    od;
    return true;
end;

# note that pres holds presentation in spin
# ignore the last element in every row
CheckRelations3 := function( sgens, pres, img )
    local dim, s, g, vec, row, x, i, y, v;

    dim := Size( sgens[1] ) - 1;
    vec := img{[Size(sgens)+1..Size(img)]};
    for row in pres{[1..NrRows(pres)]}{[1..NrCols(pres)-1]} do
        g := One(sgens[1]);
        y := One( img[1] );
        for x in row do
            i := AbsInt(x);
            if x > 0 then
                g := g * sgens[i];
                y := y * img[i];
            elif x < 0 then
                g := g * sgens[i]^-1;
                y := y * img[i]^-1;
            fi;
        od;
        if g{[1..dim]}{[1..dim]}<>IdentityMat(dim) then
            Error("error in presentation");
        fi;
        v := g{[1..dim]}[dim+1];
        if y <> Product([1..dim], i->vec[i]^v[i]) then
            return false;
        fi;
    od;
    return true;
end;

IsSpinBieberbachGroup := function( s, q )
    local dim, c, gens, imgs, i, mat;

    if s.qname <> q.name then
        Error("records do not match");
    fi;
    c := Last( GeneratorsOfGroup(q.spin_group) );
    if Image(q.lambda, c) <> One(q.point_group) then
        Error("wrong central element");
    fi;
    gens := ShallowCopy( s.generators );
    imgs := List(GeneratorsOfGroup(q.spin_group){[1..Size(gens)]}, x->[x,x*c]);

    dim  := NrRows( q.generators[1] );
    for i in [1..dim] do
        mat := IdentityMat(dim+1);
        mat[i][dim+1] := 1;
        Add(gens, mat);

        Add(imgs, [One(c), c]);
    od;
    s.spin_images := First( Cartesian(imgs), img->CheckRelations2(s.generators, img) and CheckRelations3(s.generators, q.presentation, img) );
    s.is_spin := s.spin_images <> fail;
    return s.is_spin;
end;

CheckSpinStructures := function(slist, qlist, v...)
    local log, r;

    if Size(v)=0 or v[1]<>true then
        log := function(v...) end;
    else
        log := Print;
    fi;
    for r in slist do
        log("checking ", r.name, " ... \c");
        IsSpinBieberbachGroup(r, First(qlist, q->q.name=r.qname));
        log(r.is_spin, "\n");
    od;
end;
