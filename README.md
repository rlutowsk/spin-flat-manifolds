# Calculate spin structures on low dimensional flat manifolds

Calculate flat manifolds with or without spin structure in dimensions up to 6. The algorithm is described in the article [^1].

## Prerequisities

1. The following tools are used to obtain the results:

    - bash: we use some scripting
    - [maxima](https://maxima.sourceforge.io/): needed to work with Clifford algebras
    - [GAP](https://www.gap-system.org/)
    - [CARAT](https://lbfm-rwth.github.io/carat/), available also as GAP package
    - [HAPCryst](https://gap-packages.github.io/hapcryst/) GAP package
2. Change data in `carat-env.sh` to reflect the GAP and CARAT setup. Import the variables to the session:

    ```bash
    source carat-env.sh
    ```

## Step 0: Generating Bieberbach groups

Here is an example way of generating low dimensional, i.e. up to dimension 6, Bieberbach groups.

> [!NOTE]
> The results of the following calculations have been saved in the files `qdata.g` and `bieberbach.g`, which are the part of this repository. This step can be skipped.

> [!TIP]
> The `qtoz.sh` and `extensions.sh` scripts accept an option `-j number_of_jobs`, which makes them run in parallel. This will be noted in brackets, e.g. `[ -j 16 ]`.

> [!CAUTION]
> This section uses only shell's commands, which should be invoked from within the root folder of the source tree.

> [!CAUTION]
> In the following, the folder `/tmp/data` is used to store all calculations. Any change of it **must** be reflected in the following pieces of code.

1. Copy CARAT files holding representatives of $\mathbb Q$-classes and their presentations:

    ```bash
    $ ./qcopy /tmp/data
    ```
1. Generate representatives of $\mathbb Z$-classes:

    ```bash
    $ ./qtoz.sh [ -j 16 ] /tmp/data
    ```
    **Note:** We are interesting in generating torsion-free crystallographic groupsm we can filter those $\mathbb Q$-classes, for which there exists an element without eigenvalue $1$. This id the default behaviour of the `qtoz.sh` script. It is slower at this stage, but saves time at the next one. For generating all $\mathbb Z$-classes, use the `-a` switch:

    ```bash
    $ ./qtoz.sh -a [ -j 16 ] /tmp/data
    ```
1. Generate torsion-free extensions for every representative of the $\mathbb Z$-classes:

    ```bash
    $ ./extensions.sh [ -j 16 ] /tmp/data
    ```
1. Write names and generators of low dimensional Bieberbach groups to `bieberbach.g` file:

    ```bash
    $ gap -b -c 'Read("names.g"); b:=ReadAffCaratDir("/tmp/data"); str:=String(b); RemoveCharacters(str, " \r\t\n"); PrintTo("bieberbach.g", "return ", str, ";" ); quit;'
    ```

1. We will also need the data of $\mathbb Q$-classes in GAP:

    ```bash
    $ gap -b -c 'Read("names.g"); q:=ReadQCaratDir("/tmp/data"); str:=String(q); RemoveCharacters(str, " \r\t\n"); PrintTo("qdata.g", "return ", str, ";" ); quit;'
    ```

> [!TIP]
> One can check the results by counting number of generated files. Data is taken from [CARAT doc](https://lbfm-rwth.github.io/carat/doc/) website:
> 
> ```bash
> $ ./count.sh -aqz /tmp/data
> Number of Q classes: 8329    # total number of Q-classes
> Number of Z classes: 44691   # number of Z-classes without -a switch for qtoz.sh; with this switch the result should be 92185
> Number of Aff classes: 39893 # total number of low dimensional Bieberbach groups
> ```

## Step 1: Preparing data for Bieberbach groups

> [!NOTE]
> In this step we are working with GAP.

> [!IMPORTANT]
> Whenever we say about a Bieberbach group $\Gamma$, it fits the following short exact sequence:
> 
> $$ 0  \longrightarrow \mathbb{Z}^n \longrightarrow \Gamma \stackrel{r}{\longrightarrow} G \longrightarrow 1$$

1. Read the $\mathbb Q$ and $\text{Aff}$ data:

    ```bash
    gap> qdata := ReadAsFunction( "qdata.g" )();;
    gap> adata := ReadAsFunction( "bieberbach.g" )();;
    ```

1. Load the `code.g` file:

    ```gap
    gap> Read( "code.g" );
    ```
1. The `ParseAffData` function generates basic information for Bieberbach groups from `adata`, which are needed for further calculations. For a group $\Gamma$ these include:

    - orientability
    - $\mathbb Q$-class of $G$ (from `qdata`)
    - the CARAT name of the subgroup $r^{-1}(\text{Syl}_2(G))$ (the preimage of the Sylow $2$-subgroup of $G$)
    - the dimension of $H^1(\Gamma, \mathbb{F}_2)$

    Here are the options to run the function (see the note that follows):

    - the default (minimal set of information):

        ```gap
        gap> ParseAffData( qdata, adata );
        ```
    - calculate info for all groups:

        ```gap
        gap> ParseAffData( qdata, adata : all );
        ```
    - calculate the first cohomology

        ```gap
        gap> ParseAffData( qdata, adata : cohomology );
        ```
    - calculate all information:

        ```gap
        gap> ParseAffData( qdata, adata : all, cohomology);
        ```
> [!NOTE]
> 
> If $\Gamma$ is not orientable, the rest of the info is not needed, since $\Gamma$ is not spin. For the sake of time of the execution, the default behaviour of the `ParseAffData` function is as follows:
>
> a) determine orientability of $\Gamma$  
> b) if $\Gamma$ is orientable, calculate $\mathbb Q$-class of $G$ and $\pi^{-1}(\text{Syl}_2(G))$

## Step 2: Lifts of certain holonomy groups to $\text{Spin}(n)$

The crucial step is the determination of spin structures on flat manifolds with 2-group holonomy. We are interested in:

- orientable, in our case those which lie in $\text{SL}(n,\mathbb{Q})$, groups
- of dimension greater than $3$ - up to this dimension all manifolds are spin 

1. Orientable Bieberbach groups with $2$-group holonomy $\mathbb{Q}$-classes of their holonomy groups can be obtained by:

    ```gap
    gap> oq2data := FilteredOrientable2PointGroupQData( adata, 4 );;
    ```

    We get 63 classes to work with further. One Can check their names:

    ```gap
    gap> List( oq2data, x->x.name );
    ```

2. Now comes the part where we look for lifts of generators of the group. This is done by hand (we can use methods from the article). The data is stored in `sdata.mac` file.

> [!TIP]
> The code is not included here, but one can use `PrintMaximaMatrix` function to generate data, which is already in `sdata.mac` file. As written above, the lifts to $\text{Spin}(n)$ must be calculated by hand.  
> To get a permutation, which corresponds to a signed permutation matrix, one can use the following code:
> ```gap
> gap> mat := [[0,0,-1,0],[1,0,0,0],[0,0,0,1],[0,1,0,0]];; # example data
> gap> PermList( List( TransposedMat(mat), row->PositionProperty(row,x->x in [-1,1])) );
> ```
> Note that we follow convention of CARAT to act from the left.

3. In order to work with Clifford algebras, we use Maxima. The `run` function involves:

    a) checking if the groups lie in $O(n,\mathbb{Z})$ (almost all are)  
    b) checking whether we generated inverses of elements of $\text{Spin}(n)$  
    c) checking whether the elements of $\text{Spin}(n)$ are in fact lifts of the generators  
    d) generating the presentation of lift of the holonomy groups

    The following should be run in Maxima:

    ```maxima
    (%i1) load( "sdata.mac" );
    (%i2) load( "scode.mac" );
    (%i3) run(false); /* true to use verbose mode */
    (%i4) print_to_file( "sdata.g", A );
    ```

> [!IMPORTANT]
> Let us be more precise about the presentation. If $\lambda \colon \text{Spin}(n) \to O(n)$ is the covering map, $G$ is as above, then its lift to spin is a central extension
> 
> $$ 1 \longrightarrow \{ \pm 1 \} \longrightarrow \widetilde G \stackrel{\lambda}{\longrightarrow} G \longrightarrow 1.$$
> 
> Hence in the presentation of $\widetilde G$ we get a central element $c$ of order $2$. The only nontrivial calculations involve lifting presentation of $G$, i.e. if $w$ is a relator in $G$, $\widetilde w$ - its lift to $\widetilde G$, then either $\widetilde w = 1$ or $\widetilde w = c$. This is a task of the step d).

## Step 3: Spin structures for low dimensional Bieberbach groups

1. Having proper data from Maxima, we can use GAP to generate the holonomy groups and their lifts to $\text{Spin}(n)$. The `FillSpinQData` function, called by `FillSpinAffData`, will check for consistence of the data generated by Maxima with the data so far calculated by GAP.

    ```gap
    gap> sdata := ReadAsFunction( "sdata.g" )();;
    gap> FillSpinAffData( adata, oq2data, sdata );
    ```

## Step 4: Statistics

The following GAP instructions allow to recreate statistics presented in the last section of the article [^1].

1. Get the names of orientable, non-orientable, spin and non-spin groups:

    ```gap
    gap> a_orientable := List( [1..6], dim->List(Filtered( adata, x->x.orientable and NrRows(x.generators[1])=dim+1 ), x->x.name));;
    gap> a_non_orientable := List( [1..6], dim->List(Filtered( adata, x->not x.orientable and NrRows(x.generators[1])=dim+1 ), x->x.name));;
    gap> a_spin := List( [1..6], dim->List(Filtered( adata, x->x.is_spin and NrRows(x.generators[1])=dim+1 ), x->x.name));;
    gap> a_non_spin := List( [1..6], dim->List(Filtered( adata, x->not x.is_spin and NrRows(x.generators[1])=dim+1 ), x->x.name));;
    ```
1. Get the names of $\mathbb Q$ and $\mathbb Z$ classes of orientable, non-orientable, spin and non-spin groups:

    ```gap
    gap> z_orientable := List(a_orientable, a->SSortedList(a, ZNameByAffName));;
    gap> q_orientable := List(a_orientable, a->SSortedList(a, QNameByAffName));;
    gap> z_non_orientable := List(a_non_orientable, a->SSortedList(a, ZNameByAffName));;
    gap> q_non_orientable := List(a_non_orientable, a->SSortedList(a, QNameByAffName));;
    gap> z_spin := List(a_spin, a->SSortedList(a, ZNameByAffName));;
    gap> q_spin := List(a_spin, a->SSortedList(a, QNameByAffName));;
    gap> z_non_spin := List(a_non_spin, a->SSortedList(a, ZNameByAffName));;
    gap> q_non_spin := List(a_non_spin, a->SSortedList(a, QNameByAffName));;
    ```

> [!NOTE]
> Tables 2 and 3 will give data for dimensions up to 6. Table 1, because of its length, will be shown at the end of this note.

$\mathbb Z$ classes of groups with and without spin structures:

```gap
gap> Intersection( z_spin[5], z_non_spin[5] );
[ "group.361.1.1", "min.66.1.1", "min.66.1.3", "min.70.1.1", "min.70.1.15", "min.70.1.2", "min.70.1.3", "min.70.1.7", "min.71.1.1", "min.71.1.25", "min.85.1.3" ]
```

$\mathbb Q$ classes of the above $\mathbb Z$ classes:
```gap
gap> SSortedList( Intersection( z_spin[5], z_non_spin[5] ), QNameByZName);
[ "group.361.1", "min.66.1", "min.70.1", "min.71.1", "min.85.1" ]
```

We get 100 $\mathbb Z$ classes, collected in 37 $\mathbb Q$ classes for which there exist groups with and without spin structures:

```gap
gap> Size(Intersection( z_spin[6], z_non_spin[6] ));
100
gap> Size( SSortedList( Intersection( z_spin[6], z_non_spin[6] ), QNameByZName) );
37
```

### Table 2

- all classes

    ```gap
    gap> List( q_orientable, Size ) + List( q_non_orientable, Size );
    [ 1, 2, 8, 25, 95, 397 ]
    ```
- classes of orientable groups

    ```gap
    gap> List( q_orientable, Size );
    [ 1, 1, 6, 10, 41, 106 ]
    ```

- classes of groups for which there exist groups with spin structures

    ```gap
    gap> List( q_spin, Size );
    [ 1, 1, 6, 10, 35, 92 ]
    ```

### Table 3

- all groups

    ```gap
    gap> List( a_orientable, Size ) + List( a_non_orientable, Size );
    [ 1, 2, 10, 74, 1060, 38746 ]
    ```
- orientable groups

    ```gap
    gap> List( a_orientable, Size );
    [ 1, 1, 6, 27, 174, 3314 ]
    ```
- spin groups

    ```gap
    gap> List( a_spin, Size );
    [ 1, 1, 6, 24, 88, 760 ]
    ```

### Table 1

The following code will produce the output table (in markdown syntax). The one that is ommited in the original article is marked in bold here.

```gap
gap> aspin5 := Filtered( adata, x->x.is_spin and x.qdata.dim=5);;
gap> max := List( TransposedMat( aspin5 ), x->Maximum( List(x, y->Length(String(y))) ) );
gap> for l in aspin5 do; row := List([1..4], i->String(l[i], max[i])); Print( JoinStringsWithSeparator(row, " | "), "\n"); od;
```

|       $\Gamma'$ |         $G'$ |      $r^{-1}(G)$ | $\#S$|
|----------------|-------------|-----------------|----:|
|    min.58.1.1.0 |            1 |     min.58.1.1.0 | 32|
|    min.59.1.1.1 |           C2 |     min.59.1.1.1 | 32|
|    min.62.1.1.1 |           C2 |     min.62.1.1.1 | 32|
|    min.62.1.2.1 |           C2 |     min.62.1.2.1 | 16|
|    min.62.1.3.1 |           C2 |     min.62.1.3.1 |  8|
|    min.65.1.1.7 |      C2 x C2 |     min.65.1.1.7 | 16|
|   min.66.1.1.11 |      C2 x C2 |    min.66.1.1.11 | 16|
|   min.66.1.3.11 |      C2 x C2 |    min.66.1.3.11 |  8|
|   min.70.1.1.20 |      C2 x C2 |    min.70.1.1.20 | 32|
|   min.70.1.1.22 |      C2 x C2 |    min.70.1.1.22 | 16|
|   min.70.1.1.28 |      C2 x C2 |    min.70.1.1.28 | 16|
|   min.70.1.1.30 |      C2 x C2 |    min.70.1.1.30 | 16|
|   min.70.1.1.76 |      C2 x C2 |    min.70.1.1.76 | 16|
|   min.70.1.1.77 |      C2 x C2 |    min.70.1.1.77 | 16|
|   min.70.1.1.94 |      C2 x C2 |    min.70.1.1.94 | 16|
|    min.70.1.2.9 |      C2 x C2 |     min.70.1.2.9 | 16|
|   min.70.1.2.25 |      C2 x C2 |    min.70.1.2.25 |  8|
|    min.70.1.3.7 |      C2 x C2 |     min.70.1.3.7 | 16|
|   min.70.1.3.11 |      C2 x C2 |    min.70.1.3.11 |  8|
|    min.70.1.4.7 |      C2 x C2 |     min.70.1.4.7 | 16|
|    min.70.1.4.9 |      C2 x C2 |     min.70.1.4.9 |  8|
|   min.70.1.4.10 |      C2 x C2 |    min.70.1.4.10 |  8|
|   min.70.1.4.11 |      C2 x C2 |    min.70.1.4.11 |  8|
|    min.70.1.6.3 |      C2 x C2 |     min.70.1.6.3 |  8|
|   min.70.1.7.13 |      C2 x C2 |    min.70.1.7.13 |  8|
|   min.70.1.7.15 |      C2 x C2 |    min.70.1.7.15 |  8|
|   min.70.1.14.1 |      C2 x C2 |    min.70.1.14.1 |  4|
|   min.70.1.15.5 |      C2 x C2 |    min.70.1.15.5 |  8|
|  min.70.1.15.19 |      C2 x C2 |   min.70.1.15.19 | 16|
|  min.71.1.1.362 | C2 x C2 x C2 |   min.71.1.1.362 | 16|
|  min.71.1.1.371 | C2 x C2 x C2 |   min.71.1.1.371 |  8|
|  min.71.1.1.373 | C2 x C2 x C2 |   min.71.1.1.373 | 16|
|  min.71.1.1.375 | C2 x C2 x C2 |   min.71.1.1.375 |  8|
|  min.71.1.1.378 | C2 x C2 x C2 |   min.71.1.1.378 |  8|
|  min.71.1.1.382 | C2 x C2 x C2 |   min.71.1.1.382 |  8|
|  min.71.1.25.95 | C2 x C2 x C2 |   min.71.1.25.95 | 16|
|    min.75.1.1.1 |           C4 |     min.75.1.1.1 |  8|
|    min.79.1.1.1 |           C4 |     min.79.1.1.1 | 16|
|    min.79.1.2.2 |           C4 |     min.79.1.2.2 |  8|
|    min.81.1.1.1 |           C4 |     min.81.1.1.1 | 16|
|    min.81.1.3.1 |           C4 |     min.81.1.3.1 |  8|
|    min.81.1.6.1 |           C4 |     min.81.1.6.1 |  8|
|   min.85.1.1.41 |           D8 |    min.85.1.1.41 | 16|
|   min.85.1.1.42 |           D8 |    min.85.1.1.42 |  8|
|   min.85.1.1.44 |           D8 |    min.85.1.1.44 |  8|
|   min.85.1.1.45 |           D8 |    min.85.1.1.45 |  8|
|   min.85.1.1.46 |           D8 |    min.85.1.1.46 |  8|
|   min.85.1.3.19 |           D8 |    min.85.1.3.19 |  4|
|   min.85.1.3.22 |           D8 |    min.85.1.3.22 |  8|
|   min.86.1.13.5 |           D8 |    min.86.1.13.5 |  4|
|   min.86.1.13.6 |           D8 |    min.86.1.13.6 |  8|
|   min.86.1.13.7 |           D8 |    min.86.1.13.7 |  4|
|   min.90.1.10.3 |      C4 x C2 |    min.90.1.10.3 |  4|
|   min.98.1.3.12 |      C4 x C2 |    min.98.1.3.12 |  4|
|   min.101.1.1.1 |           C3 |     min.58.1.1.0 |  2|
|   min.104.1.1.1 |           C3 |     min.58.1.1.0 |  8|
|   min.104.1.2.1 |           C3 |     min.58.1.1.0 |  8|
|   min.106.1.1.1 |           C6 |     min.62.1.1.1 |  8|
|   min.107.1.1.2 |           S3 |     min.62.1.2.1 |  8|
|   min.107.1.2.1 |           S3 |     min.62.1.3.1 |  4|
|   min.107.2.1.2 |           S3 |     min.62.1.2.1 |  8|
|   min.107.2.2.1 |           S3 |     min.62.1.3.1 |  4|
|   min.107.2.3.2 |           S3 |     min.62.1.2.1 |  8|
|   min.107.2.4.1 |           S3 |     min.62.1.3.1 |  4|
|   min.110.1.1.1 |           C6 |     min.59.1.1.1 |  8|
|   min.110.1.3.1 |           C6 |     min.59.1.1.1 |  8|
|   min.123.1.1.1 |          C12 |     min.79.1.1.1 |  4|
|   min.124.1.1.1 |          C12 |     min.81.1.1.1 |  4|
|   min.129.1.1.1 |           C6 |     min.62.1.1.1 |  2|
|   min.129.1.2.1 |           C6 |     min.62.1.3.1 |  2|
|  min.130.1.1.12 |      C3 x C3 |     min.58.1.1.0 |  2|
|  min.130.1.1.37 |      C3 x C3 |     min.58.1.1.0 |  2|
|  min.130.1.3.10 |      C3 x C3 |     min.58.1.1.0 |  2|
|   min.131.1.2.3 |           A4 |   min.70.1.15.19 |  4|
|   min.131.2.1.3 |           A4 |    min.70.1.1.76 |  4|
|   min.132.1.2.3 |      C2 x A4 |   min.71.1.25.95 |  4|
|   min.132.2.1.6 |      C2 x A4 |   min.71.1.1.373 |  4|
|   min.134.1.2.2 |           S4 |    min.86.1.13.6 |  4|
|**min.141.1.1.1**|       **C8** | **min.141.1.1.1**|**4**|
|   min.154.1.1.1 |          C12 |     min.75.1.1.1 |  2|
|   min.164.1.1.1 |           C5 |     min.58.1.1.0 |  2|
|group.240.2.1.11 |           D8 | group.240.2.1.11 |  8|
| group.326.1.1.1 |           C6 |     min.59.1.1.1 |  2|
| group.341.1.1.1 |           C6 |     min.62.1.1.1 |  8|
|group.361.1.1.21 |          D12 |     min.70.1.3.7 |  8|
|group.361.1.1.22 |          D12 |    min.70.1.3.11 |  4|
|group.541.1.1.10 |      C6 x C3 |     min.62.1.1.1 |  2|
| group.994.1.1.1 |          C10 |     min.59.1.1.1 |  2|

[^1]: R. Lutowski, B. Putrycz, *Spin structures on flat manifolds*, J. Algebra 436 (2015), 277-291, DOI: [j.jalgebra.2015.03.037](https://doi.org/10.1016/j.jalgebra.2015.03.037)
