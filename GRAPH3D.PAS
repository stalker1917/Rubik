unit graph3d;




interface


uses  vectors, useful, bitmap,Vcl.Forms,Graphics,OpenGl,Windows;


const
  buffersize=64000;
  maxverticescount=1000;
  maxtrianglescount=1000;
  maxlightscount=10;
  precision=0.0001;


type
  tscrbuffer = Graphics.TBitMap;//array [0..buffersize-1] of LongWord;  //256 ·‡ÈÚ
  twbuffer = array {[0..buffersize-1]} of single;
  tcamera = record
    position, direction, up: tvector;
    end;

  tobject = object
    firstvertex, lastvertex, firsttriangle, lasttriangle: longint;
    position, direction, up: tvector;
    procedure show;
    procedure hide;
    procedure move(const v: tvector);
    procedure rotate(const c, n: tvector; a: single);
    procedure setposition(const p: tvector);
    procedure setdirection(const d: tvector);
    procedure setup(const u: tvector);
    procedure setmaterial(var m: tmaterial);
    end;
  type
  Single1_2 = array [1..2] of single;
  ttriangle = record
    visible: boolean;
    vertexid: array [1..3] of longint;
    tc: array [1..3] of Single1_2;//array [1..2] of single;
    material: PMaterial;
    end;


procedure opengraph(ss, sw, sh: integer);
procedure closegraph;
procedure updatescreen;
procedure converttobasis(const x, e1, e2, e3: tvector; var v: tvector);
procedure addlight(const p: tvector);
function computelighting(n: longint): single;
function computelightingcolor(color: LongWord; l: single): LongWord;
procedure drawline(x1, y1, x2, y2: integer; color: byte);
procedure drawtriangle(n: integer);
procedure worldtocamera(const x: tvector; var v: tvector);
procedure cameratoscreen(const v: tvector; var x, y: integer);
procedure worldtoscreen(const v: tvector; var x, y: integer );
procedure rendertobuffer;
procedure render;
procedure loadbitmap(var b: bitmap.tbitmap; var w: byte; n: string);
function SafeDiv(Dividend:Double;Divider:Double):Double;
function SafeIntDiv(Dividend,Divider:Integer):Double;


var
  buffer: tscrbuffer;
  wbuffer: twbuffer;
  scrsc, scrwidth, scrheight, trianglescount, verticescount: integer;
  vertex: array [1..maxverticescount] of tvector;
  scrvertex: array [1..maxverticescount] of array [1..2] of integer;
  zvertex: array [1..maxverticescount] of single;
  triangle: array [1..maxtrianglescount] of ttriangle;
  light: array [1..maxlightscount] of tvector;
  lightscount, backgroundcolor: byte;
  camera: tcamera;
  Form3D:TForm;
  ghRC:HGLRC;
  ghDC:HDC;



implementation
function bSetupPixelFormat(DC:HDC):boolean;
var
    pfd:PIXELFORMATDESCRIPTOR;
    ppfd:PPIXELFORMATDESCRIPTOR;
    pixelformat:integer;
begin
    ppfd := @pfd;

    ppfd.nSize := sizeof(PIXELFORMATDESCRIPTOR);
    ppfd.nVersion := 1;
    ppfd.dwFlags :=  PFD_DRAW_TO_WINDOW xor
                     PFD_SUPPORT_OPENGL xor
                     PFD_DOUBLEBUFFER;
    ppfd.dwLayerMask := PFD_MAIN_PLANE;
    ppfd.iPixelType := PFD_TYPE_RGBA;
    ppfd.cColorBits := 16;
    ppfd.cDepthBits := 16;

    ppfd.cAccumBits := 0;
    ppfd.cStencilBits := 0;

    pixelformat := ChoosePixelFormat(dc, ppfd);
    if pixelformat=0 then
    begin
        MessageBox(0, 'ChoosePixelFormat failed', 'Error', MB_OK);
        bSetupPixelFormat:=FALSE;
        exit;
    end;

    if SetPixelFormat(dc, pixelformat, ppfd)=false then
    begin
        MessageBox(0, 'SetPixelFormat failed', 'Error', MB_OK);
        bSetupPixelFormat:=FALSE;
        exit;
    end;

    bSetupPixelFormat:=TRUE;
end;

procedure InitOpenGl;
 var
   p: TGLArrayf4;
   d,a:TGLArrayf3;
   i,j:Integer;
   buf:byte;
begin
   ghDC := GetDC(Form3D.Handle);
   if bSetupPixelFormat(ghDC)=false then
     Form3d.Close();
   ghRC := wglCreateContext(ghDC);
   wglMakeCurrent(ghDC, ghRC);

   glClearColor(0.0, 0.0, 0.0, 0.0);

 //  Form1.FormResize(Form1);

  // glEnable(GL_COLOR_MATERIAL);
  // glDisable(GL_DEPTH_TEST);
   glEnable(GL_DEPTH_TEST);
   glDepthFunc(Gl_LESS);
   glShadeModel(GL_Smooth);

     p[0]:=200;
     p[1]:=200;
     p[2]:=200;
     p[3]:=1;
     d[0]:=0;
     d[1]:=0;
     d[2]:=0;
     a[0]:=1;
     a[1]:=1;
     a[2]:=1;
  // glLightfv(GL_LIGHT0,GL_AMBIENT,@a);
   glLightfv(GL_LIGHT0,GL_POSITION,@p);
   glLightfv(GL_LIGHT0,GL_SPOT_DIRECTION,@d);
    //glEnable(GL_LIGHTING);
   // glEnable(GL_LIGHT0);
   glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    glMatrixMode( GL_MODELVIEW );
   glPushMatrix;
  // for i:=1 to 6 do
   //begin
   //Photo_Tex[i]:=100+i;
   //LoadingBitmap(Configure.Put[i],photo_image[i]);
  // end;
end;

function SafeIntDiv(Dividend,Divider:Integer):Double;
begin
  if Divider=0 then result := Dividend
               else result := Dividend/Divider;
end;

function SafeDiv;
begin
  if Divider<0.001 then
  result := Dividend*1000
  else result := Dividend/Divider;
end;

procedure tobject.show;
var
  i: longint;
begin
  for i:=firsttriangle to lasttriangle do
    triangle[i].visible:=true;
end;


procedure tobject.hide;
var
  i: longint;
begin
  for i:=firsttriangle to lasttriangle do
    triangle[i].visible:=false;
end;


procedure tobject.move(const v: tvector);
var
  i: integer;
begin
  for i:=firstvertex to lastvertex do
    addvector(v, vertex[i], vertex[i]);
  addvector(v, position, position);
end;


procedure tobject.rotate(const c, n: tvector; a: single);
var
  i: integer;
  v: tvector;
begin
  for i:=firstvertex to lastvertex do
    rotatevector(c, n, a, vertex[i]);
  rotatevector(c, n, a, position);
  nullvector(v);
  rotatevector(v, n, a, direction);
  rotatevector(v, n, a, up);
end;

procedure tobject.setposition(const p: tvector);
var
  v: tvector;
begin
  subtractvector(p, position, v);
  move(v);
end;


procedure tobject.setdirection(const d: tvector);
var
  v, v1: tvector;
  l: single;
begin

end;


procedure tobject.setup(const u: tvector);
var
  v, v1: tvector;
  l: single;
begin

end;


procedure tobject.setmaterial(var m: tmaterial);
var
  i: integer;
begin
  for i:=firsttriangle to lasttriangle do
    triangle[i].material:=@m;
end;



procedure opengraph(ss, sw, sh: integer);
//var
  //regs: registers;
begin
  InitOpenGl;
  scrsc:=ss;
  scrwidth:=sw;
  scrheight:=sh;
  //regs.ah:=$00;
  //regs.al:=$13;
 // intr($10, regs);
  //screen:=ptr($a000, 0);
  buffer:= Graphics.TBitMap.Create;
  buffer.Width := sw;
  buffer.Height := sh;
  SetLength(wBuffer,sw*sh);
  //new(wbuffer);
  trianglescount:=0;
  verticescount:=0;
  lightscount:=0;
  backgroundcolor:=0;
  with camera do
  begin
    setvector(position, 0, 0, 0);
    setvector(direction, 0, 1, 0);
    setvector(up, 0, 0, 1);
  end;
end;


procedure closegraph;

begin

  buffer.Destroy;
  SetLength(wbuffer,0);

end;


procedure updatescreen;
var
  i: longint;
begin
SwapBuffers(ghDC);
glClear(GL_DEPTH_BUFFER_BIT xor GL_COLOR_BUFFER_BIT);
glDisable(GL_TEXTURE_2D);
glClearColor(0,0,0,0);
glMatrixMode( GL_PROJECTION );
 glLoadIdentity();
 gluPerspective(20.0,1.5,0.2,800);
gluLookAt(camera.position[1],camera.position[2],camera.position[3],
camera.direction[1],camera.direction[2],camera.direction[3],
camera.up[1], camera.up[2],camera.up[3]);
glMatrixMode( GL_MODELVIEW );
//glPopMatrix;
//glPushMatrix;

//glRotatef(-Angl, 0,1,0);

{
   Form3d.Canvas.Draw(1,1,buffer);
  for i:=scrwidth*scrheight-1 downto 0 do
  begin
    //screen^[i]:=buffer^[i];

    //Form3d.Canvas.Pixels[i mod scrwidth,i div scrwidth] := buffer.Canvas.Pixels[i mod scrwidth,i div scrwidth];
    buffer.Canvas.Pixels[i mod scrwidth,i div scrwidth]:=backgroundcolor;
    wbuffer[i]:=0;
  end;
  }
end;


procedure converttobasis(const x, e1, e2, e3: tvector; var v: tvector);
var
  e, s: array [1..3] of tvector;
  udet: single;
begin
  copyvector(e[1], e1);
  copyvector(e[2], e2);
  copyvector(e[3], e3);
  udet:=1/(e[1][1]*e[2][2]*e[3][3]+e[2][1]*e[3][2]*e[1][3]+e[3][1]*e[1][2]*e[2][3]-
       e[3][1]*e[2][2]*e[1][3]-e[2][1]*e[1][2]*e[3][3]-e[1][1]*e[3][2]*e[2][3]);
  s[1][1]:=e[2][2]*e[3][3]-e[3][2]*e[2][3];
  s[2][1]:=e[3][2]*e[1][3]-e[1][2]*e[3][3];
  s[3][1]:=e[1][2]*e[2][3]-e[2][2]*e[1][3];
  s[1][2]:=e[3][1]*e[2][3]-e[2][1]*e[3][3];
  s[2][2]:=e[1][1]*e[3][3]-e[3][1]*e[1][3];
  s[3][2]:=e[2][1]*e[1][3]-e[1][1]*e[2][3];
  s[1][3]:=e[2][1]*e[3][2]-e[3][1]*e[2][2];
  s[2][3]:=e[3][1]*e[1][2]-e[1][1]*e[3][2];
  s[3][3]:=e[1][1]*e[2][2]-e[2][1]*e[1][2];
  v[1]:=(s[1][1]*x[1]+s[1][2]*x[2]+s[1][3]*x[3])*udet;
  v[2]:=(s[2][1]*x[1]+s[2][2]*x[2]+s[2][3]*x[3])*udet;
  v[3]:=(s[3][1]*x[1]+s[3][2]*x[2]+s[3][3]*x[3])*udet;
end;


procedure addlight(const p: tvector);
begin
  inc(lightscount);
  light[lightscount]:=p;
end;


function computelighting(n: longint): single;
var
  i: byte;
  v1, v2, v: tvector;
  l, tl: single;
begin
  with triangle[n] do
  begin
    v1[1]:=vertex[vertexid[2]][1]-vertex[vertexid[1]][1];
    v1[2]:=vertex[vertexid[2]][2]-vertex[vertexid[1]][2];
    v1[3]:=vertex[vertexid[2]][3]-vertex[vertexid[1]][3];
    v2[1]:=vertex[vertexid[3]][1]-vertex[vertexid[1]][1];
    v2[2]:=vertex[vertexid[3]][2]-vertex[vertexid[1]][2];
    v2[3]:=vertex[vertexid[3]][3]-vertex[vertexid[1]][3];
  end;
  vectorproduct(v1, v2, v);
  normalizevector(v);
  l:=0;
  for i:=1 to lightscount do
  begin
    tl:=vectordotproduct(v, light[i]);
    if tl>0 then l:=l+tl;
    if l>=1 then begin l:=1; break; end;
  end;
  computelighting:=l;
end;


function computelightingcolor(color: LongWord; l: single): LongWord;
var
  R,G,B,i: byte;
begin
    R := Color mod 256;
    G := (Color mod 65536) div 256;
    B := Color div 65536;
   // if R>255 then

    R := Round(R*l);
    G := Round(G*l);
    B := Round(B*l);
    Result := R+256*G+65536*B;
end;




procedure drawline(x1, y1, x2, y2: integer; color: byte);
var
  d: single;
  i, dx, dy: integer;
begin
  dx:=x2-x1;
  dy:=y2-y1;
  if abs(dx)>=abs(dy) then
  begin
    d:=dy/dx;
    if x1>x2 then begin swapi(x1, x2); swapi(y1, y2); end;
    for i:=x2-x1 downto 0 do
      buffer.Canvas.Pixels[x1+i,round(d*i+y1)] :=color;
     // ^[+round(d*i+y1)*scrwidth]:=color;
  end
  else
  begin
    d:=dx/dy;
    if y1>y2 then begin swapi(x1, x2); swapi(y1, y2); end;
    for i:=y2-y1 downto 0 do
     buffer.Canvas.Pixels[round(d*i+x1),(y1+i)] := color;
     // buffer^[round(d*i+x1)+(y1+i)*scrwidth]:=color;
  end;
end;


procedure drawtriangle(n: integer);

var
  v1, v2, v3, v, bx, by, bz: tvector;
  x1, y1, x2, y2, x3, y3, tcx1, tcy1, tcx2, tcy2, tcx3, tcy3, i, j, ti1, ti2, sj, t1, t2, w, dcx, dcy, dcx1, dcy1, dcx2, dcy2: integer;
  p: longint;
  ttcx1, ttcx2, ttcy1, ttcy2,  k: byte;
  cl:LongWord;
  uz1, uz2, uz3, d1, d3, duz, duz1, duz3, tuz1, tuz2, tz, tn, z1, z2, z3, tz1, tz2, dtz, dtz1, l, t, tl, dz, dz1, dz2, dy, dy1, dy2, j1, j3: single;
  btm, bmm: bitmap.tbitmap;
  bump: boolean;
  normlight: array [1..maxlightscount] of tvector;
  //drawstring: procedure;
  Ûesdrawtexture : Boolean;
  R,G,B : Single;

procedure findbasis(xy: byte);
var
  itc: array [1..3] of integer;
begin
  with triangle[n] do
    if xy=3 then
    begin
      subtractvector(vertex[vertexid[2]], vertex[vertexid[1]], v1);
      subtractvector(vertex[vertexid[3]], vertex[vertexid[1]], v2);
      vectorproduct(v1, v2, bz);
      normalizevector(bz);
    end
    else
    begin
      itc[1]:=1; itc[2]:=2; itc[3]:=3;
      if tc[itc[1]][xy]>=tc[itc[2]][xy] then swapi(itc[1], itc[2]);
      if tc[itc[2]][xy]>=tc[itc[3]][xy] then
      begin
        swapi(itc[2], itc[3]);
        if tc[itc[1]][xy]>tc[itc[2]][xy] then swapi(itc[1], itc[2]);
      end;
      subtractvector(vertex[vertexid[itc[3]]], vertex[vertexid[itc[1]]], v1);
      scalevector(v1, (tc[itc[2]][xy]-tc[itc[1]][xy])/(tc[itc[3]][xy]-tc[itc[1]][xy]));
      subtractvector(vertex[vertexid[itc[1]]], vertex[vertexid[itc[2]]], v2);
      if xy=1 then
      begin
        addvector(v1, v2, bx);
        normalizevector(bx);
      end
      else
      if xy=2 then
      begin
        addvector(v1, v2, by);
        normalizevector(by);
      end;
    end;
end;

function computebump: single;
var k:Integer;
begin
  setvector(v, (bmm[p-w]-bmm[p])/4, 1, (bmm[p-1]-bmm[p])/4);
  normalizevector(v);
  t:=0;
  for k:=1 to lightscount do
  begin
    tl:=vectordotproduct(v, normlight[k]);
    if tl>0 then t:=t+tl;
    if t>=1 then begin t:=1; break; end;
  end;
  computebump:=t;
end;

procedure drawcoloredstring; //far;
var i:Integer;
begin
  if t1>t2 then
  begin
    tz:=(t2-t1)*duz+tuz1;
    swapi(t1, t2);
  end
  else tz:=tuz1;
  for i:=t1 to t2-1 do
  begin
    if tz>wbuffer[i] then
    begin
      buffer.Canvas.Pixels[i mod scrwidth,i div scrwidth]:=cl;
      wbuffer[i]:=tz;
    end;
    tz:=tz+duz;
  end;
end;

procedure drawtexturedstring; //far;
var i:Integer;
begin
  if t1>t2 then
  begin
    tz:=(t2-t1)*duz+tuz1;
    swapi(t1, t2);
  end
  else tz:=tuz1;
  {if abs(tz2-tz1)<precision then
  begin
    tn:=(j-dy)*dy1;
    ttcx1:=dcx+trunc(dcx1*tn); ttcy1:=dcy+trunc(dcy1*tn);
    tn:=(j-y1)*dy2;
    ttcx2:=tcx1+trunc(dcx2*tn); ttcy2:=tcy1+trunc(dcy2*tn);
    dtz:=1/(t2-t1);
    tn:=0;
    for i:=t1 to t2-1 do
    begin
      if tz>wbuffer^[i] then
      begin
        p:=ttcx1+trunc((ttcx2-ttcx1)*tn)+w*trunc((ttcy1+(ttcy2-ttcy1)*tn));
        if bump then l:=computebump;
        buffer^[i]:=computelightingcolor(btm^[p], l);
        wbuffer^[i]:=tz;
      end;
      tn:=tn+dtz;
      tz:=tz+duz;
    end;
  end
  else     }
  //begin
    tn:=(tz1-dz)*dz1;
    ttcx1:=dcx+trunc(dcx1*tn); ttcy1:=dcy+trunc(dcy1*tn);
    tn:=(tz2-z1)*dz2;
    ttcx2:=tcx1+trunc(dcx2*tn); ttcy2:=tcy1+trunc(dcy2*tn);
    if (tz2-tz1)>0.001 then dtz:=1/(tz2-tz1)
                       else dtz:=1000;
    dtz1:=tz1*dtz;
    for i:=t1 to t2-1 do
    begin
      tn:=dtz/tz-dtz1;
      if tz>wbuffer[i] then
      begin
        p:=ttcx1+trunc((ttcx2-ttcx1)*tn)+w*trunc((ttcy1+(ttcy2-ttcy1)*tn));
        if P>High(Btm) then p:= High(Btm);
        if P<0 then p:=0;
        if bump then l:=computebump;
        buffer.Canvas.Pixels[i mod scrwidth,i div scrwidth]:=computelightingcolor(btm[p], l);
        wbuffer[i]:=tz;
      end;
      tz:=tz+duz;
    end;
  //end;
end;

procedure DrawString(drawtexture:Boolean);
begin
  if drawtexture then drawtexturedstring
                 else drawcoloredstring;

end;

begin
with triangle[n] do
  begin
  cl := material^.color;
  R := (Cl mod 256)/256;
  G := ((Cl div 256) mod 256)/256;
  B := (Cl div 65536)/256;
  glColor3f(R,G,B);
	glBegin(GL_TRIANGLES);  //left
  for i := 1 to 3 do
     glVertex3f(vertex[vertexid[i]][1]/3,vertex[vertexid[i]][2]/3,vertex[vertexid[i]][3]/3);
	glEnd();
end;

{
  with triangle[n] do
  begin
    x1:=scrvertex[vertexid[1]][1]; y1:=scrvertex[vertexid[1]][2];
    x2:=scrvertex[vertexid[2]][1]; y2:=scrvertex[vertexid[2]][2];
    x3:=scrvertex[vertexid[3]][1]; y3:=scrvertex[vertexid[3]][2];
    v1[1]:=x2-x1; v1[2]:=y2-y1; v1[3]:=0;
    v2[1]:=x3-x1; v2[2]:=y3-y1; v2[3]:=0;
    vectorproduct(v1, v2, v);
    if v[3]>0 then
    begin
      z1:=zvertex[vertexid[1]]; z2:=zvertex[vertexid[2]]; z3:=zvertex[vertexid[3]];
      w:=material^.width;
      if material^.bitmap<>nil then
      begin
        dec(w);
        tcx1:=trunc(tc[1][1]*w); tcy1:=trunc(tc[1][2]*w);
        tcx2:=trunc(tc[2][1]*w); tcy2:=trunc(tc[2][2]*w);
        tcx3:=trunc(tc[3][1]*w); tcy3:=trunc(tc[3][2]*w);
        inc(w);
        btm:=material^.bitmap;
        bump:=false;
        if material^.bumpmap=nil then l:=computelighting(n)
        else
        begin
          bump:=true;
          findbasis(1); findbasis(2); findbasis(3);
          for i:=1 to lightscount do
          begin
            converttobasis(light[i], bx, bz, by, normlight[i]);
            normalizevector(normlight[i]);
          end;
          bmm:=material^.bumpmap;
        end;
        Ûesdrawtexture := True;
        //drawstring:=drawtexturedstring;
      end
      else
      begin
        cl:=computelightingcolor(material^.color, computelighting(n));
        Ûesdrawtexture := False;
        //drawstring:=drawcoloredstring;
      end;
      if y1>y2 then begin swapi(y1, y2); swapi(x1, x2); swaps(z1, z2); swapi(tcx1, tcx2); swapi(tcy1, tcy2); end;
      if y2>y3 then
      begin
        swapi(y2, y3); swapi(x2, x3); swaps(z2, z3); swapi(tcx2, tcx3); swapi(tcy2, tcy3);
        if y1>y2 then begin swapi(y1, y2); swapi(x1, x2); swaps(z1, z2); swapi(tcx1, tcx2); swapi(tcy1, tcy2); end;
      end;
      uz1:=1/z1; uz2:=1/z2; uz3:=1/z3;
      duz3:=SafeDiv((uz3-uz1),(y3-y1));
      duz1:=SafeDiv((uz2-uz1),(y2-y1));
      d3:=SafeIntDiv((x3-x1),(y3-y1));
      d1:=SafeIntDiv((x2-x1),(y2-y1));
      ti1:=x1-trunc(y1*d1); ti2:=x1-trunc(y1*d3);
      sj:=y1*scrwidth;
      tuz1:=uz1; tuz2:=uz1;
      dcx1:=tcx2-tcx1; dcy1:=tcy2-tcy1; dz1:=1/(z2-z1); dcx:=tcx1; dcy:=tcy1;
      dcx2:=tcx3-tcx1; dcy2:=tcy3-tcy1; dz2:=1/(z3-z1); dz:=z1;
      dy:=y1;
      dy1:=SafeIntDiv(1,(y2-y1));
      dy2:=SafeIntDiv(1,(y3-y1));
      j1:=y1*d1; j3:=y1*d3;
      for j:=y1 to y2 do
        begin
        tz1:=1/tuz1; tz2:=1/tuz2;
        t1:=ti1+trunc(j1)+sj; t2:=ti2+trunc(j3)+sj;
        j1:=j1+d1; j3:=j3+d3;
        //div by zero
        if (t2-t1)>1 then duz:=(tuz2-tuz1)/(t2-t1)
                          else duz := tuz2-tuz1;
        drawstring(Ûesdrawtexture);
        sj:=sj+scrwidth;
        tuz1:=tuz1+duz1; tuz2:=tuz2+duz3;
        end;
      if y3<>y2 then
       begin
        duz1:=(uz3-uz2)/(y3-y2);
        d1:=(x3-x2)/(y3-y2);
       end
      else
        begin
          duz1:=(uz3-uz2);
          d1:=(x3-x2);
        end;

      ti1:=x3-trunc(y3*d1); ti2:=x3-trunc(y3*d3);
      tuz1:=uz2; tuz2:=uz1+(y2-y1)*duz3;
      dcx1:=tcx3-tcx2; dcy1:=tcy3-tcy2; dz1:=1/(z3-z2); dz:=z2; dcx:=tcx2; dcy:=tcy2;
      dy:=y2;
      if y3<>y2 then dy1:=1/(y3-y2)
                else dy1:=1;
      j1:=y2*d1; j3:=y2*d3;
      for j:=y2+1 to y3 do
        begin
        j1:=j1+d1; j3:=j3+d3;
        t1:=ti1+trunc(j1)+sj; t2:=ti2+trunc(j3)+sj;
        tuz1:=tuz1+duz1; tuz2:=tuz2+duz3;
        tz1:=1/tuz1; tz2:=1/tuz2;
        if (t2-t1)>1 then duz:=(tuz2-tuz1)/(t2-t1)
                          else duz := tuz2-tuz1;
        //duz:=(tuz2-tuz1)/(t2-t1);
        drawstring(Ûesdrawtexture);
        sj:=sj+scrwidth;
        end;
    end;
  end;
}
end;


procedure worldtocamera(const x: tvector; var v: tvector);
var
  x1, x2, x3: tvector;
begin
  with camera do
  begin
    vectorproduct(up, direction, x1);
    normalizevector(x1);
    vectorproduct(direction, x1, x2);
    normalizevector(x2);
    subtractvector(x, camera.position, x3);
    converttobasis(x3, x1, x2, direction, v);
    v[1]:=-v[1];
  end;
end;


procedure cameratoscreen(const v: tvector; var x, y: integer);
var
  v3: single;
begin
  v3:=scrsc/v[3];
  x:=(scrwidth shr 1)+round(v3*v[1]);
  y:=(scrheight shr 1)-round(v3*v[2]);
end;


procedure worldtoscreen(const v: tvector; var x, y: integer );
var
  v1: tvector;
begin
  worldtocamera(v, v1);
  cameratoscreen(v1, x, y);
end;


procedure rendertobuffer;
var
  i: longint;
  v: tvector;
begin
  for i:=1 to verticescount do
  begin
    worldtocamera(vertex[i], v);
    zvertex[i]:=v[3];
    cameratoscreen(v, scrvertex[i][1], scrvertex[i][2]);
  end;
  for i:=1 to trianglescount do if triangle[i].visible then drawtriangle(i);
end;


procedure render;
begin
  rendertobuffer;
  updatescreen;
end;


procedure loadbitmap(var b: bitmap.tbitmap; var w: byte; n: string);
var
  p: tpalette;
  t: string;
begin
  t:=n;
  delete(t, 1, length(n)-3);
  if t='bmp' then
    bmpload(b, w, p, n);
end;



end.