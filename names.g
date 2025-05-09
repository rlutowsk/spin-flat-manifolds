ReadCaratDir := function(dir, switch)
    local str, out;
    if not switch in [ "-q", "-z", "-a" ] then
        Error("Wrong switch value");
    fi;
    str := "";
    out := OutputTextString( str, true );
    Process( DirectoryCurrent(), Filename( DirectoryCurrent(), "names.sh" ), InputTextNone(), out, [ switch, dir ] );
    CloseStream( out );
    if switch = "-a" then
        return List( EvalString(str), name->rec(generators:=CaratReadMatrixFile(name), name:=Last( SplitString(name,"/") ) ) );
    elif switch = "-q" then
        return List( EvalString(str), 
        function(name) 
            local r, d; 
            r := CaratReadBravaisFile(name); 
            d := SplitString(name,"/"); 
            r.name := Remove( d );
            Add(d, Concatenation("pres.", r.name) );
            r.presentation := CaratReadMatrixFile( JoinStringsWithSeparator(d, "/") );
            return r; 
        end );
    fi;
    return List( EvalString(str), function(name) local r; r:=CaratReadBravaisFile(name); r.name:=Last( SplitString(name,"/") ); return r; end );
end;

ReadQCaratDir := function( dir )
    return ReadCaratDir( dir, "-q" );
end;

ReadZCaratDir := function( dir )
    return ReadCaratDir( dir, "-z" );
end;

ReadAffCaratDir := function( dir )
    return ReadCaratDir( dir, "-a" );
end;
