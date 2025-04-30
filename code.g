SPIN_DIR := Directory("~/spin-flat-manifolds");
CARAT_NAME_SCRIPT := Filename(SPIN_DIR, "name.sh");

LoadPackage("hapcryst");

InfoSpinBieberbach := NewInfoClass("InfoSpinBieberbach");

#################################################################################
#
# QClass
#
# Caltulations with representatives of finite subgroups of GL(n,Q)
#
#################################################################################

#################################################################################
#
# This function assumes that with every file holding generators of group
# there exists a `pres.` prefixed file holding its presentation.
#
QDataByFilenames := function(filename)
    local names, qdata, n, r, t;

    names := ReadAsFunction( filename )();;
    qdata := [];
    for n in names do
        Info( InfoSpinBieberbach, 2, "Parsing qdata for ", n, " ... " );
        r := CaratReadBravaisFile( n );
        r.dim := Size( r.generators[1] );
        t := SplitString( n, "/" );
        r.name := Last( t );
        t[Size(t)] := Concatenation( "pres.", Last(t) );
        r.presentation := CaratReadMatrixFile( JoinStringsWithSeparator(t, "/") );
        r.orientable := ForAll( r.generators, x->Determinant(x)>0 );
        if not IsBound( r.size ) then
            # fix the records without size component
            r.size := Size( Group(r.generators) );
        fi;
        Add( qdata, r );
    od;
    return qdata;
end;

ParseQData := function(l...)
    local filein, fileout, qdata, str;

    if Size(l) >= 1 then
        filein := l[1];
    else
        filein := "qnames.g";
    fi;
    if Size(l) >= 2 then
        fileout := l[2];
    else
        fileout := "qdata.g";
    fi;
    Info( InfoSpinBieberbach, 1, "Reading filenames from ", filein, " ... " );
    qdata := QDataByFilenames( filein );
    Info( InfoSpinBieberbach, 1, "Writing qdata to ", fileout, " ... " );
    str := String( qdata );
    RemoveCharacters( str, " \r\t\n" );
    PrintTo( fileout, "return ", str, ";" );

    return qdata;
end;

WriteCaratQData := function(data, dirname)
    local r, contents, err;

    contents := DirectoryContents( dirname );
    if contents = fail then
        err := LastSystemError();
        Error("Error opening ", dirname, ": ", err.message);
    fi;
    if Size(contents) > 2 then
        Error("The directory ", dirname, " must be empty");
    fi;

    Info( InfoSpinBieberbach, 1, "Writing matrix files to ", dirname, " ... " );
    for r in data do
        Info( InfoSpinBieberbach, 2, "Writing ", r.name, " ... " );
        CaratWriteBravaisFile( Concatenation( dirname, "/", r.name ), r );
        CaratWriteMatrixFile( Concatenation( dirname, "/pres.", r.name ), r.presentation );
    od;
end;

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

AffDataByFilenames := function(filename)
    local anames, adata, n, r, t;

    anames := ReadAsFunction( filename )();;
    adata  := [];;
    for n in anames do
        Info( InfoSpinBieberbach, 2, "Parsing aff data for ", n, " ... " );
        r := rec();
        r.generators := CaratReadMatrixFile( n );
        t := SplitString( n, "/" );
        r.name := Last(t);
        t := SplitString( r.name, "." );
        r.qname := Concatenation(t[1], ".", t[2]);
        Add( adata, r );
    od;

    return adata;
end;

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
    local dim, i, tmp, egens, sgrp, iso, img;

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
    if GroupHomology( img, 0 ) <> [0] then
        Error("First homology is not Z");
    fi;
    return Size( Filtered(GroupHomology(img, 1), IsEvenInt) );
end;

FillRankOneCohomologyMod2 := function( data )
    local r;
    Info( InfoSpinBieberbach, 1, "Calculating ranks of one cohomologies mod 2 ...");
    for r in data do
        Info( InfoSpinBieberbach, 2, "Calculating one cohomology mod 2 rank for ", r.name ," ... " );
        r.one_cohomology_mod2 := RankOneCohomologyMod2( r.generators );
    od;
end;

ParseAffData := function(qdata, l...)
    local filein, fileout, filename, adata, r, str;

    if Size(l) >= 1 then
        filein := l[1];
    else
        filein := "anames.g";
    fi;
    if Size(l) >= 2 then
        fileout := l[2];
    else
        fileout := "adata.g";
    fi;
    Info( InfoSpinBieberbach, 1, "Reading filenames from ", filein, " ... " );
    adata := AffDataByFilenames( filein );
    Info( InfoSpinBieberbach, 1, "Attaching qdata to aff data ... " );
    for r in adata do
        r.qdata := First(qdata, x->x.name = r.qname);
        if r.qdata = fail then
            Error("Cannot find ", r.qname, " in qdata");
        else
            Unbind(r.qname);
        fi;
    od;
    Info( InfoSpinBieberbach, 1, "Calculating generators of preimages of Sylow 2 subgroups ... " );
    for r in adata do
        Info( InfoSpinBieberbach, 2, "Calculating generators of preimage of Sylow 2 subgroup for ", r.name ," ... " );
        if r.qdata.size>1 and r.qdata.size=2^Log2Int(r.qdata.size) then
            r.s2generators := ShallowCopy( r.generators );
        elif IsOddInt( r.qdata.size ) then
            r.s2generators := [ IdentityMat(r.qdata.dim+1) ];
        else
            r.s2generators := AffPreImageSyl2Generators( r.generators );
        fi;
    od;
    Info( InfoSpinBieberbach, 1, "Calculating names of Sylow 2 subgroup ... " );
    filename  := CaratTmpFile("group");
    for r in adata do
        Info( InfoSpinBieberbach, 2, "Calculating name of preimage of Sylow 2 subgroup for ", r.name ," ... " );
        if r.s2generators = r.generators then
            r.s2name := r.name;
        else
            r.s2name := CaratNameByGenerators(r.s2generators, filename);
        fi;
    od;
    FillRankOneCohomologyMod2( adata );
    Info( InfoSpinBieberbach, 1, "Writing aff data to ", fileout, " ... " );
    str := String( adata );
    RemoveCharacters( str, " \r\t\n" );
    PrintTo( fileout, "return ", str, ";" );

    return adata;
end;

RanksCohomologyMod2 := function(generators)
    local dim, i, tmp, egens, sgrp, res, cc, half, coh;

    egens := List( generators, TransposedMat );
    dim   := NrRows( generators[1] ) - 1;
    for i in [1..dim] do
        tmp := IdentityMat( dim+1 );
        tmp[dim+1][i] := 1;
        Add( egens, tmp );
    od;
    sgrp := AffineCrystGroupOnRight( egens );
    Info( InfoSpinBieberbach, 3, "Calculating resolution ...");
    res  := ResolutionBieberbachGroup( sgrp );
    cc   := HomToIntegersModP( res, 2 );
    if IsEvenInt( dim ) then
        half := dim/2;
    else
        half := (dim-1)/2;
    fi;
    coh := [];
    for i in [0..half] do
        Info( InfoSpinBieberbach, 3, "Calculating H^", i, " ...");
        Add(coh, Cohomology(cc, i));
    od;
    for i in [half+1..dim] do
        coh[i+1] := coh[dim-i+1];
    od;
    return coh;
end;

FillCohomologyMod2 := function( data )
    local a;
    for a in data do
        Info( InfoSpinBieberbach, 2, "Calculating mod 2 cohomology for ", a.name, " ... ");
        a.hmod := RanksCohomologyMod2( a.generators );
    od;
end;

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
    p := List( [1..n-1], i->Comm(f[i], f[n]) );
    Add( p, f[n]^2 );
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
    if arec.no_of_spin > 0 and arec.no_of_spin<>2^arec.one_cohomology_mod2 then
        Error("Number of spin structures not power of 2 for ", arec.name);
    fi;
    arec.is_spin := arec.no_of_spin > 0;
    return arec.is_spin;
end;

FillSpinAffData := function( adata, qdata, sdata )
    local a, q, b, force;
    
    force := ValueOption("force")=true;

    FillSpinQData( qdata, sdata);
    for a in adata do
        Info( InfoSpinBieberbach, 2, "Generating spin data for ", a.name , " ... " );
        if not a.qdata.orientable then
            a.is_spin := false;
            continue;
        fi;
        if IsOddInt(a.qdata.size) or a.qdata.dim<=3 then
            a.is_spin := true;
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
            continue;
        fi;
        q := First( qdata, x->x.name = b.qdata.name );
        if q = fail then
            Error("Cannot find qdata match for ", b.name);
        fi;
        b.qdata := q;
        IsSpinBieberbachGroupByRec( b );
        a.is_spin := b.is_spin;
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
