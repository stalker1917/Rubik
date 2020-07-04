// -------------Original----
//made by Oleksii Gryniuk
//compiler: TMT Pascal Lite
//release date: 11.06.2010
// modification for Delphi 10
// Stalker 1917
// 2020

unit rubics1;

interface
uses vectors, graph3d, primitiv,useful,logical;//, crt, mouse;

var
  c: array [-1..1, -1..1, -1..1] of tobject;
  t: array [-1..1, -1..1, -1..1] of ^tobject;
  m: array [1..9] of ^tobject;
  tnormal, v, v0, tv, v1, v2, nv: tvector;
  a, b, tb: single;
  key: char;
  n, button: byte;
  sign: shortint;
  ret: array [1..1000] of array [1..2] of byte;
  steps, mx, my, l: integer;
  x, y, mc: word;
  returning, turned: boolean;
  ci, cj, ck, ci0, cj0, ck0: shortint;
  str1, str2: string;
  procedure turncamera(mx, my: integer);
  Procedure  setcoloredmaterials;
  Procedure  settexturedmaterials;
  Procedure  setwhitematerials;
  Procedure  setwhitebumpmaterials;
  Procedure  createcube;
  Procedure  createasymmetriccube;
  Procedure  createstrangecube;
  procedure  update;
  procedure turn(n: byte; a: single);
  procedure mix(n: integer);
  procedure processcursor;
  function getundermouse(var mi, mj, mk: shortint): integer;
implementation




function isontriangle(x, y, i1, i2, i3: integer): boolean;
var
  v1, v2, v3: array [1..2] of integer;
  a1, a2, a3: integer;
begin
  v1[1]:=scrvertex[i1][1]-x; v1[2]:=scrvertex[i1][2]-y;
  v2[1]:=scrvertex[i2][1]-x; v2[2]:=scrvertex[i2][2]-y;
  v3[1]:=scrvertex[i3][1]-x; v3[2]:=scrvertex[i3][2]-y;
  a1:=v1[1]*v2[2]-v1[2]*v2[1];
  a2:=v2[1]*v3[2]-v2[2]*v3[1];
  a3:=v3[1]*v1[2]-v3[2]*v1[1];
  if (abs(a1)+abs(a2)+abs(a3)=abs(a1+a2+a3))
     and ((scrvertex[i3][1]-scrvertex[i1][1])*(scrvertex[i2][2]-scrvertex[i1][2])
         -(scrvertex[i3][2]-scrvertex[i1][2])*(scrvertex[i2][1]-scrvertex[i1][1])<0)
     and (((abs(vertex[i1][1])>1) or (abs(vertex[i1][2])>1) or (abs(vertex[i1][3])>1))
       and ((abs(vertex[i2][1])>1) or (abs(vertex[i2][2])>1) or (abs(vertex[i2][3])>1))
       and ((abs(vertex[i3][1])>1) or (abs(vertex[i3][2])>1) or (abs(vertex[i3][3])>1)))
     and (zvertex[i1]<=(Safediv(1,(wbuffer[scrvertex[i1][1]+320*scrvertex[i1][2]]))+0.1))
     and (zvertex[i2]<=(Safediv(1,(wbuffer[scrvertex[i2][1]+320*scrvertex[i2][2]]))+0.1))
     and (zvertex[i3]<=(Safediv(1,(wbuffer[scrvertex[i3][1]+320*scrvertex[i3][2]]))+0.1))   then
    isontriangle:=true
  else isontriangle:=false;
end;

function min3s(a, b, c: single): single;
var
  min: single;
begin
  if a<b then min:=a else min:=b;
  if min>c then min3s:=c else min3s:=min;
end;

function getundermouse(var mi, mj, mk: shortint): integer;
var
  i, j, k: shortint;
  zmin: single;
  l, tr: integer;
begin
  tr:=0;
  zmin:=100;
  for i:=-1 to 1 do
    for j:=-1 to 1 do
      for k:=-1 to 1 do
        if (i<>0) or (j<>0) or (k<>0) then
          for l:=c[i,j,k].firsttriangle to c[i,j,k].lasttriangle do
            if ((zmin>zvertex[triangle[l].vertexid[1]]) or (zmin>zvertex[triangle[l].vertexid[2]]) or (zmin>zvertex[triangle[l].vertexid[3]]))
               and isontriangle(x, y, triangle[l].vertexid[1], triangle[l].vertexid[2], triangle[l].vertexid[3]) then
            begin
              zmin:=min3s(zvertex[triangle[l].vertexid[1]], zvertex[triangle[l].vertexid[2]], zvertex[triangle[l].vertexid[3]]);
              tr:=l;
              mi:=round(c[i,j,k].position[1]); mj:=round(c[i,j,k].position[2]); mk:=round(c[i,j,k].position[3]);
            end;
  getundermouse:=tr;
end;

procedure drawlinedtriangle(l: integer; color: byte);
begin
  drawline(scrvertex[triangle[l].vertexid[1]][1], scrvertex[triangle[l].vertexid[1]][2], scrvertex[triangle[l].vertexid[2]][1], scrvertex[triangle[l].vertexid[2]][2], color);
  drawline(scrvertex[triangle[l].vertexid[2]][1], scrvertex[triangle[l].vertexid[2]][2], scrvertex[triangle[l].vertexid[3]][1], scrvertex[triangle[l].vertexid[3]][2], color);
  drawline(scrvertex[triangle[l].vertexid[3]][1], scrvertex[triangle[l].vertexid[3]][2], scrvertex[triangle[l].vertexid[1]][1], scrvertex[triangle[l].vertexid[1]][2], color);
end;

procedure drawcursor(x, y: integer);
var
  i, j, w: byte;
begin
  w:=cursor.width;
  for i:=0 to w-1 do
    for j:=0 to w-1 do
      if cursor.bitmap[i+w*j]<>cursor.bitmap[w*(w-1)] then
        buffer.Canvas.Pixels[x+i,(j+y)]:=cursor.bitmap[i+w*j];
end;

procedure setcoloredmaterials;
begin

  white.color:=255+255*65536+255*256;//31;
  mat.color:=64+64*65536+64*256;
  yellow.color:=255+255*256;;
  red.color:=255;
  green.color:=255*256;
  blue.color:=255*65536;
  orange.color:=255+128*256;
  logo.color := white.color;
  //loadbitmap(logo.bitmap, logo.width, 'logo0.bmp');
end;

procedure setwhitematerials;
begin
  mat.color:=20;
  white.color:=31;
  yellow.color:=31;
  red.color:=31;
  green.color:=31;
  blue.color:=31;
  orange.color:=31;
  loadbitmap(logo.bitmap, logo.width, 'logo0.bmp');
end;

procedure setwhitebumpmaterials;
begin
  mat.color:=20;
  loadbitmap(red.bitmap, red.width, 'white.bmp');
  loadbitmap(green.bitmap, green.width, 'white.bmp');
  loadbitmap(blue.bitmap, blue.width, 'white.bmp');
  loadbitmap(white.bitmap, white.width, 'white.bmp');
  loadbitmap(yellow.bitmap, yellow.width, 'white.bmp');
  loadbitmap(orange.bitmap, orange.width, 'white.bmp');
  loadbitmap(logo.bitmap, logo.width, 'logo.bmp');
  loadbitmap(red.bumpmap, red.width, 'bump.bmp');
  loadbitmap(green.bumpmap, green.width, 'bump.bmp');
  loadbitmap(blue.bumpmap, blue.width, 'bump.bmp');
  loadbitmap(white.bumpmap, white.width, 'bump.bmp');
  loadbitmap(yellow.bumpmap, yellow.width, 'bump.bmp');
  loadbitmap(orange.bumpmap, orange.width, 'bump.bmp');
  loadbitmap(logo.bumpmap, logo.width, 'bump.bmp');
end;

procedure settexturedmaterials;
begin
  mat.color:=21;
  loadbitmap(red.bitmap, red.width, 'red.bmp');
  loadbitmap(green.bitmap, green.width, 'green.bmp');
  loadbitmap(blue.bitmap, blue.width, 'blue.bmp');
  loadbitmap(white.bitmap, white.width, 'white.bmp');
  loadbitmap(yellow.bitmap, yellow.width, 'yellow.bmp');
  loadbitmap(orange.bitmap, orange.width, 'orange.bmp');
  loadbitmap(logo.bitmap, logo.width, 'logo.bmp');
  loadbitmap(red.bumpmap, red.width, 'bump.bmp');
  loadbitmap(green.bumpmap, green.width, 'bump.bmp');
  loadbitmap(blue.bumpmap, blue.width, 'bump.bmp');
  loadbitmap(white.bumpmap, white.width, 'bump.bmp');
  loadbitmap(yellow.bumpmap, yellow.width, 'bump.bmp');
  loadbitmap(orange.bumpmap, orange.width, 'bump.bmp');
  loadbitmap(logo.bumpmap, logo.width, 'bump.bmp');
end;

procedure createcube;
var
   i, j, k: shortint;
   m: tvector;
begin
for i:=-1 to 1 do
    for j:=-1 to 1 do
        for k:=-1 to 1 do
          if (i<>0) or (j<>0) or (k<>0) then
          begin
            make_cube(c[i,j,k], 0.95);
            t[i,j,k]:=@c[i,j,k];
            setvector(m, i, j, k);
            c[i,j,k].move(m);
            c[i,j,k].setmaterial(mat);
            if j=-1 then
            begin
              triangle[trianglescount].material:=Rubik.GetMaterial(3,i,j,k);//@green;
              triangle[trianglescount-1].material:=Rubik.GetMaterial(3,i,j,k);///@green;
            end;
            if i=1 then
            begin
              triangle[trianglescount-2].material:=Rubik.GetMaterial(4,i,j,k);//@red;
              triangle[trianglescount-3].material:=Rubik.GetMaterial(4,i,j,k);//@red;
            end;
            if k=1 then
            begin
              triangle[trianglescount-4].material:=Rubik.GetMaterial(1,i,j,k);//@white;
              triangle[trianglescount-5].material:=Rubik.GetMaterial(1,i,j,k);//@white;
             { if (i=0) and (j=0) then
              begin
                triangle[trianglescount-4].material:=@logo;
                triangle[trianglescount-5].material:=@logo;
              end;}
            end;
            if i=-1 then
            begin
              triangle[trianglescount-6].material:=Rubik.GetMaterial(2,i,j,k);//@orange;
              triangle[trianglescount-7].material:=Rubik.GetMaterial(2,i,j,k);//@orange;
            end;
            if k=-1 then
            begin
              triangle[trianglescount-8].material:=Rubik.GetMaterial(6,i,j,k);//@yellow;
              triangle[trianglescount-9].material:=Rubik.GetMaterial(6,i,j,k);//@yellow;
            end;
            if j=1 then
            begin
              triangle[trianglescount-10].material:=Rubik.GetMaterial(5,i,j,k);//@blue;
              triangle[trianglescount-11].material:=Rubik.GetMaterial(5,i,j,k);//@blue;
            end;
          end;
end;

procedure createasymmetriccube;
var
  i: integer;
begin
  createcube;
  for i:=1 to verticescount do
  begin
    if vertex[i][1]>1 then vertex[i][1]:=2
    else if vertex[i][1]<-1 then vertex[i][1]:=-1;
    if vertex[i][2]>1 then vertex[i][2]:=1.8
    else if vertex[i][2]<-1 then vertex[i][2]:=-1.2;
    if vertex[i][3]>1 then vertex[i][3]:=1.6
    else if vertex[i][3]<-1 then vertex[i][3]:=-1.4;
  end;
end;

procedure createstrangecube;
var
  i: integer;
begin
  createcube;
  for i:=1 to verticescount do
    if ((abs(vertex[i][1])>1) and (abs(vertex[i][2])<1) and (abs(vertex[i][3])<1))
    or ((abs(vertex[i][1])<1) and (abs(vertex[i][2])>1) and (abs(vertex[i][3])<1))
    or ((abs(vertex[i][1])<1) and (abs(vertex[i][2])<1) and (abs(vertex[i][3])>1)) then
    begin
      vertex[i][1]:=vertex[i][1]*1.2;
      vertex[i][2]:=vertex[i][2]*1.2;
      vertex[i][3]:=vertex[i][3]*1.2;
    end
    else if (abs(vertex[i][1])>1) and (abs(vertex[i][2])>1) and (abs(vertex[i][3])>1) then
    begin
      vertex[i][1]:=vertex[i][1]*0.87;
      vertex[i][2]:=vertex[i][2]*0.87;
      vertex[i][3]:=vertex[i][3]*0.87;
    end;
end;

procedure setturningface(i, j, k: shortint);
begin
  setvector(tnormal, i, j, k);
  if i<>0 then
    for j:=-1 to 1 do
      for k:=-1 to 1 do
        m[3*j+k+5]:=t[i,j,k]
  else if j<>0 then
    for i:=-1 to 1 do
      for k:=-1 to 1 do
        m[3*i+k+5]:=t[i,j,k]
  else if k<>0 then
    for i:=-1 to 1 do
      for j:=-1 to 1 do
        m[3*i+j+5]:=t[i,j,k];
end;

procedure turnface(a: single);
var
  i: byte;
begin
  for i:=1 to 9 do
    m[i]^.rotate(v0, tnormal, a);
end;

procedure turn(n: byte; a: single);
begin
  case n of
  1:
    setturningface(1, 0, 0);
  2:
    setturningface(-1, 0, 0);
  3:
    setturningface(0, 1, 0);
  4:
    setturningface(0, -1, 0);
  5:
    setturningface(0, 0, 1);
  6:
    setturningface(0, 0, -1);
  end;
  turnface(a);
end;

procedure update;
var
  i, j, k, pb: shortint;
  pv: tvector;
  pa: single;
begin
  for i:=-1 to 1 do
    for j:=-1 to 1 do
      for k:=-1 to 1 do
        if (i<>0) or (j<>0) or (k<>0) then
          t[round(c[i,j,k].position[1]), round(c[i,j,k].position[2]), round(c[i,j,k].position[3])]:=@c[i,j,k];
end;

procedure mix(n: integer);
var
  i, t: byte;
begin
  randomize;
  for i:=n-1 downto 0 do
  begin
    t:=random(5)+1;
    turn(t, pi/2);
    inc(steps);
    ret[steps][1]:=t;
    ret[steps][2]:=1;
    update;
  end;
end;

procedure turncamera(mx, my: integer);
var
  tv1, tv2: tvector;
begin
  nullvector(v0);
  with camera do
  begin
    rotatevector(v0, up, mx*0.01, position);
    vectorproduct(up, direction, tv1);
    normalizevector(tv1);
    rotatevector(v0, tv1, my*0.01, position);
    subtractvector(v0, position, direction);
    normalizevector(direction);
    vectorproduct(up, direction, tv2);
    vectorproduct(direction, tv2, up);
    normalizevector(up);
    copyvector(light[1], direction);
    copyvector(light[2], direction);
  end;
end;

procedure processcursor;
var
  v1, v2: tvector;
begin
  if (abs(ci)+abs(cj)+abs(ck)>1) and (abs(ci0)+abs(cj0)+abs(ck0)>1) then
  begin
    subtractvector(vertex[triangle[l].vertexid[2]], vertex[triangle[l].vertexid[1]], v1);
    subtractvector(vertex[triangle[l].vertexid[3]], vertex[triangle[l].vertexid[1]], v2);
    vectorproduct(v1, v2, nv);
    if round(nv[1])<>0 then nv[1]:=ci
    else if round(nv[2])<>0 then nv[2]:=cj
    else if round(nv[3])<>0 then nv[3]:=ck;
    setvector(v1, ci-ci0, cj-cj0, ck-ck0);
    vectorproduct(nv, v1, v2); normalizevector(v2);
    v2[1]:=round(v2[1]); v2[2]:=round(v2[2]); v2[3]:=round(v2[3]);
    sign:=-1;
    if v2[1]<>0 then
    begin
      if ci=1 then n:=1 else n:=2;
      if v2[1]=ci then sign:=1;
    end
    else if v2[2]<>0 then
    begin
      if cj=1 then n:=3 else n:=4;
      if v2[2]=cj then sign:=1;
    end
    else if v2[3]<>0 then
    begin
      if ck=1 then n:=5 else n:=6;
      if v2[3]=ck then sign:=1;
    end;
    tb:=0; inc(steps); ret[steps][1]:=n; ret[steps][2]:=sign;
  end;
  turned:=true;
end;




begin

end.