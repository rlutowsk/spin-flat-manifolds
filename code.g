SPIN_DIR := Directory("~/spin-flat-manifolds");
CARAT_NAME_SCRIPT := Filename(SPIN_DIR, "name.sh");

LoadPackage("hapcryst", false);

InfoSpinBieberbach := NewInfoClass("InfoSpinBieberbach");

#################################################################################
#
# QClass
#
# Caltulations with representatives of finite subgroups of GL(n,Q)
#
#################################################################################

QNameByAffName := function( aname )
    local s;
    s := SplitString( aname, "." );
    return Concatenation(s[1], ".", s[2]);
end;

QNameByZName := QNameByAffName;

#################################################################################
#
# ZClass
#
# Caltulations with representatives of finite subgroups of GL(n,Z)
#
#################################################################################

ZNameByAffName := function( aname )
    local s;
    s := SplitString( aname, "." );
    Remove(s);
    return JoinStringsWithSeparator(s, ".");
end;

#################################################################################
#
# AffClass
#
# Caltulations with representatives of Bieberbach groups
#
#################################################################################

AffPreImageSyl2Generators := function(generators)
    local sgrp;
    sgrp := AffineCrystGroupOnLeft( generators );
    if IsOddInt( Size(PointGroup(sgrp)) ) then
        return fail;
    fi;
    return GeneratorsOfGroup( PreImage(PointHomomorphism(sgrp), SylowSubgroup(PointGroup(sgrp),2)) );
end;

CaratNameByGenerators := function( generators, p... )
    local filename, output, err, str, name, torus, dim;

    # first handle trivial cases
    torus := [
        "min.1.1.1.0",
        "min.2.1.1.0",
        "min.6.1.1.0",
        "min.15.1.1.0",
        "min.58.1.1.0",
        "min.170.1.1.0"
    ];
    dim := NrRows(generators[1]);
    if Size(generators)=1 and generators[1]=IdentityMat(dim) then
        return torus[dim-1];
    fi;

    if Size(p) >= 1 then
        filename := p[1];
    else
        filename := CaratTmpFile("group");
    fi;
    CaratWriteMatrixFile( filename, generators );

    str    := "";
    output := OutputTextString(str, true);
    err := Process( DirectoryCurrent(), CARAT_NAME_SCRIPT, InputTextNone(), output, [filename]);
    CloseStream( output );
    name := JoinStringsWithSeparator( SplitString(str, "-"), ".");
    if Last(name) = '\n' then
        Remove(name);
    fi;
    return name;
end;

RankOneCohomologyMod2 := function(generators)
    local dim, i, tmp, egens, sgrp, iso, img, res, tr;

    egens := List( generators, TransposedMat );
    dim   := NrRows( generators[1] ) - 1;
    for i in [1..dim] do
        tmp := IdentityMat( dim+1 );
        tmp[dim+1][i] := 1;
        Add( egens, tmp );
    od;
    sgrp := AffineCrystGroupOnRight( egens );
    iso  := IsomorphismPcpGroup( sgrp );
    if iso = fail then
        Error("This method works only for solvable groups");
    fi;
    img := Image( iso );
    res := ResolutionAlmostCrystalGroup( img, 2 );
    tr  := TensorWithIntegers( res );
    if Homology( tr, 0 ) <> [0] then
        Error("First homology is not Z");
    fi;
    return Size( Filtered(Homology(tr, 1), IsEvenInt) );
end;

RankOneCohomologyMod2ByRec := function( arec )
    local force;

    force := ValueOption("force")=true;
    if not IsBound(arec.one_cohomology_mod2) or force then
        arec.one_cohomology_mod2 := RankOneCohomologyMod2( arec.generators );
    fi;
    return arec.one_cohomology_mod2;
end;

ParseAffData := function( qdata, adata )
    local filein, fileout, filename, r, str, all, cohomology;

    all := ValueOption("all")=true;
    cohomology := ValueOption("cohomology")=true;
    
    filename  := CaratTmpFile("group");

    for r in adata do
        Info( InfoSpinBieberbach, 1, "Calculating data for  ", r.name, " ... " );

        r.qname := QNameByAffName( r.name );

        r.orientable := ForAll( r.generators, x->Determinant(x)>0 );

        if not r.orientable and not all then
            continue;
        fi;

        r.qdata := First(qdata, x->x.name = r.qname);
        if r.qdata = fail then
            Error("Cannot find ", r.qname, " in qdata");
        else
            Unbind(r.qname);
        fi;

        if not IsBound( r.qdata.size ) then
            r.qdata.size := Size( Group(r.qdata.generators) );
        fi;

        if not IsBound( r.qdata.dim ) then
            r.qdata.dim := NrRows( r.qdata.generators[1] );
        fi;
    
        Info( InfoSpinBieberbach, 2, "Calculating generators of preimage of Sylow 2 subgroup for ", r.name ," ... " );
        if r.qdata.size>1 and r.qdata.size=2^Log2Int(r.qdata.size) then
            r.s2generators := ShallowCopy( r.generators );
        elif IsOddInt( r.qdata.size ) then
            r.s2generators := [ IdentityMat(r.qdata.dim+1) ];
        else
            r.s2generators := AffPreImageSyl2Generators( r.generators );
        fi;
    
        Info( InfoSpinBieberbach, 2, "Calculating name of preimage of Sylow 2 subgroup for ", r.name ," ... " );
        if r.s2generators = r.generators then
            r.s2name := r.name;
        else
            r.s2name := CaratNameByGenerators(r.s2generators, filename);
        fi;

        if cohomology then
            Info( InfoSpinBieberbach, 2, "Calculating one cohomology mod 2 rank for ", r.name ," ... " );
            r.one_cohomology_mod2 := RankOneCohomologyMod2( r.generators );
        fi;
    od;

end;

FilteredOrientable2PointGroupQData := function( adata, d... )
    local dim;
    if Length(d) >= 1 and IsPosInt(d[1]) then
        dim := d[1];
    else
        dim := 1;
    fi;
    return SSortedList( Filtered( adata, x->x.orientable and x.qdata.dim>=dim and x.qdata.size>1 and x.qdata.size = 2^Log2Int(x.qdata.size) ), x->x.qdata );
end;

# RanksCohomologyMod2 := function(generators)
#     local dim, i, tmp, egens, sgrp, res, cc, half, coh, iso, img;

#     egens := List( generators, TransposedMat );
#     dim   := NrRows( generators[1] ) - 1;
#     for i in [1..dim] do
#         tmp := IdentityMat( dim+1 );
#         tmp[dim+1][i] := 1;
#         Add( egens, tmp );
#     od;
    
#     if IsEvenInt( dim ) then
#         half := dim/2;
#     else
#         half := (dim-1)/2;
#     fi;

#     sgrp := AffineCrystGroupOnRight( egens );
#     Info( InfoSpinBieberbach, 3, "Calculating resolution ...");
#     iso  := IsomorphismPcpGroup( sgrp );
#     img  := Image( iso );
#     res  := ResolutionAlmostCrystalGroup( img, half+1 );
#     cc   := HomToIntegersModP( res, 2 );
    
#     coh := [];
#     for i in [0..half] do
#         Info( InfoSpinBieberbach, 3, "Calculating H^", i, " ...");
#         Add(coh, Cohomology(cc, i));
#     od;
#     for i in [half+1..dim] do
#         coh[i+1] := coh[dim-i+1];
#     od;
#     return coh;
# end;

#################################################################################
#
# Spin
#
# Caltulations with lifts of holonomy groups to spin
#
#################################################################################

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
    # Here we encode the action, which is trivial
    p := List( [1..n-1], i->Comm(f[i], f[n]) );
    # The center consists of involution only
    Add( p, f[n]^2 );
    # The lift of the relations in the holonomy group
    Append( p, List( mat, row->ElementFromWordVector(f, row) ) );
    return g/p;
end;

SpinData := function(qrec, srec)
    local egens;
    
    egens := ShallowCopy( qrec.generators );
    Add( egens, One(qrec.generators[1]) );

    qrec.group  := Group( qrec.generators );
    srec.group  := SpinExtensionByMat( srec.presentation );
    srec.lambda := GroupHomomorphismByImages( srec.group, qrec.group, GeneratorsOfGroup( srec.group ), egens );
    qrec.spin   := ShallowCopy( srec );
end;

FillSpinQData := function(qdata, sdata)
    local q, s, iso;

    for q in qdata do
        Info( InfoSpinBieberbach, 2, "Generating spin data for ", q.name , " ... " );
        s := First(sdata, x->x.name=q.name);
        if s=fail then
            Error("Cannot find spin data for ", q.name);
        fi;
        if q.generators <> s.generators then
            Error("generators in q and spin records different");
        fi;
        if s.generators <> s.orthogonal then
            iso := GroupHomomorphismByImages( Group(s.generators), Group(s.orthogonal), s.generators, s.orthogonal);
            if iso=fail or not IsInjective(iso) or ForAny( Source(iso), x->Trace(x)<>Trace(Image(iso,x)) ) then
                Error("Error in orthogonal representation of group in ", s.name);
            fi;
        fi;
        SpinData(q, s);
        if q.spin.lambda = fail then
            Error("Covering homomorphism not calculated for ", q.name);
        fi;
    od;
end;

CheckSpinRelations2 := function( sgens, img )
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

CheckSpinRelations3 := function( sgens, pres, img, dim )
    local s, g, vec, row, x, i, y, v;

    vec := img{[Size(sgens)+1..Size(img)]};
    for row in pres do
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

IsSpinBieberbachGroupByRec := function( arec )
    local dim, c, gens, imgs, i, mat;

    Info( InfoSpinBieberbach, 1, "Checking spin structures for ", arec.name, " ... ");
    c := Last( GeneratorsOfGroup(arec.qdata.spin.group) );
    if Image(arec.qdata.spin.lambda, c) <> One(arec.qdata.group) then
        Error("wrong central element");
    fi;
    gens := ShallowCopy( arec.generators );
    imgs := List(GeneratorsOfGroup(arec.qdata.spin.group){[1..Size(gens)]}, x->[x,x*c]);

    dim  := arec.qdata.dim;
    for i in [1..dim] do
        mat := IdentityMat(dim+1);
        mat[i][dim+1] := 1;
        Add(gens, mat);

        Add(imgs, [One(c), c]);
    od;
    arec.spin_structures := Filtered( Cartesian(imgs), img->CheckSpinRelations2(arec.generators, img) and CheckSpinRelations3(arec.generators, arec.qdata.presentation, img, dim) );
    arec.no_of_spin := Size( arec.spin_structures );

    if not IsBound( arec.one_cohomology_mod2 ) then
        arec.one_cohomology_mod2 := RankOneCohomologyMod2( arec.generators );
    fi;

    if arec.no_of_spin > 0 and arec.no_of_spin<>2^arec.one_cohomology_mod2 then
        Error("Number of spin structures not power of 2 for ", arec.name);
    fi;
    arec.is_spin := arec.no_of_spin > 0;
    return arec.is_spin;
end;

FillSpinAffData := function( adata, qdata, sdata )
    local a, q, b, force;
    
    force := ValueOption("force")=true;

    # this will join the q and spin data generated so far
    # additionally, the function do some checks on the representation
    FillSpinQData( qdata, sdata);
    for a in adata do
        Info( InfoSpinBieberbach, 2, "Generating spin data for ", a.name , " ... " );
        # the a.orientable field should be assigned with ParseAffData function
        if not a.orientable then
            a.is_spin := false;
            a.no_of_spin := 0;
            continue;
        fi;
        # for these cases we know for sure that the group is spin
        if IsOddInt(a.qdata.size) or a.qdata.dim<=3 then
            a.is_spin := true;
            RankOneCohomologyMod2ByRec( a );
            a.no_of_spin := 2^a.one_cohomology_mod2;
            continue;
        fi;
        if a.name = a.s2name then
            b := a;
        else 
            b := First( adata, x->x.name = a.s2name );
        fi;
        if b = fail then
            Error("cannot find Sylow 2 subgroup record for ", a.name);
        fi;
        if IsBound(b.is_spin) and not force then
            a.is_spin := b.is_spin;
            if (a.is_spin) then
                RankOneCohomologyMod2ByRec( a );
                a.no_of_spin := 2^a.one_cohomology_mod2;
            else
                a.no_of_spin := 0;
            fi;
            continue;
        fi;
        q := First( qdata, x->x.name = b.qdata.name );
        if q = fail then
            Error("Cannot find qdata match for ", b.name);
        fi;
        b.qdata := q;
        IsSpinBieberbachGroupByRec( b );
        a.is_spin := b.is_spin;
        # WARN: copy of the few line above!!!
        if (a.is_spin) then
            RankOneCohomologyMod2ByRec( a );
            a.no_of_spin := 2^a.one_cohomology_mod2;
        else
            a.no_of_spin := 0;
        fi;
    od;
end;

StrippedAffDataRec := function( arec )
    local r;
    r := StructuralCopy( arec );
    if IsBound( r.spin_structures ) then
        Unbind( r.spin_structures );
    fi;
    if not IsBound( r.qdata ) then
        return r;
    fi;
    if IsBound( r.qdata.group ) then
        Unbind( r.qdata.group );
    fi;
    if not IsBound( r.qdata.spin ) then
        return r;
    fi;
    if IsBound( r.qdata.spin.lambda ) then
        Unbind( r.qdata.spin.lambda );
    fi;
    if IsBound( r.qdata.spin.group ) then
        Unbind( r.qdata.spin.group );
    fi;
    return r;
end;

#################################################################################
#
# Helper functions
#
#################################################################################

PrintMaximaMatrix := function( array )
    local arr, max, l, k, maxp, compact, bl, endl;

    compact := ValueOption("compact")=true;
    endl  := ValueOption("endl")=true;
    if compact then
      maxp:=0;
      bl:="";
    else
      maxp:=1;
      bl:=" ";
    fi;
    if not IsMatrix( array ) then
        Error( "<array> must be a matrix" );
    else
        arr := List( array, x -> List( x, String ) );
        if compact then
          max:=List([1..Length(arr[1])],
            x->Maximum(List([1..Length(arr)],y->Length(arr[y][x]))));
        else
          max := Maximum( List( arr,
                    function(x)
                         if Length(x) = 0 then
                             return 1;
                         else
                             return Maximum( List(x,Length) );
                         fi;
                         end) );
        fi;

        Print( "matrix(\n");
        for l in [ 1 .. Length( arr ) ] do
                Print(bl," ");
            Print( "[",bl );
            if Length(arr[ l ]) = 0 then
                Print(bl,bl,"]" );
            else
                for k  in [ 1 .. Length( arr[ l ] ) ]  do
                  if compact then
                    Print( String( arr[ l ][ k ], max[k] + maxp ) );
                  else
                    Print( String( arr[ l ][ k ], max + maxp ) );
                  fi;
                  if k = Length( arr[ l ] )  then
                      Print( bl,"]" );
                  else
                      Print( ", " );
                  fi;
                od;
            fi;
            if l < Length( arr )  then
                Print( ",\n" );
            fi;
        od;
        Print( bl,"\n)" );
        if endl then
            Print("\n");
        fi;
    fi;
end;
