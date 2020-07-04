unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, rubics1, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses vectors, graph3d, primitiv,useful,logical;

{$R *.dfm}


procedure PrerareToKey;
begin
 rendertobuffer;
 updatescreen;
end;
procedure PostKey;
begin
  if abs(a)>0.01 then
    with camera do
    begin
      rotatevector(v0, v, a, position);
      subtractvector(v0, position, direction);
      normalizevector(direction);
      vectorproduct(up, direction, tv);
      vectorproduct(direction, tv, up);
      normalizevector(up);
      copyvector(light[1], direction);
      a:=a*0.6;
    end;
    if tb>=0 then
    begin
      turn(n, sign*b);
      tb:=tb+b;
      if tb+b>pi/2 then
      begin
        turn(n, sign*(pi/2-tb));
        tb:=-1;
        rubics1.update;
        if returning then
          if steps>0 then
          begin
            n:=ret[steps][1];
            sign:=-ret[steps][2];
            dec(steps);
            tb:=0;
          end
          else
            returning:=false;
      end;
    end;


end;


procedure CubePrepare;
begin
  steps:=0;
  rubics1.update;
  b:=pi*0.1;
  sign:=1;
  tb:=-1;
  returning:=false;
  ci0:=0; cj0:=1; ck0:=0;
  PrerareToKey;
end;

procedure TForm1.Button1Click;
begin
  Rubik.Fname := 'Position.txt';
  Rubik.LoadRubik;
  trianglescount:=0;
  verticescount:=0;
  lightscount:=0;
  createcube;
  CubePrepare;
  Memo1.Clear;
end;


procedure TForm1.Button2Click;
var
t : Cardinal;
begin
 t := GetTickCount;
  Rubik.Solve;
  //Rubik := Rubik2;
  trianglescount:=0;
  verticescount:=0;
  lightscount:=0;
  createcube;
  CubePrepare;
  Edit1.Text := FloatToStr((GetTickCount-t)/1000);
  Memo1.Lines.Add(DStrings[4]);
end;

procedure TForm1.FormCreate;
begin
  Rubik := TRubik.Create;
  Form3D := Self;
  //opengraph(200, 320, 200);
   opengraph(480, 640, 480);
  str1:='1';
  str2:='1';
  loadbitmap(useful.cursor.bitmap, useful.cursor.width, 'mouse.bmp');
  setvector(camera.position, 3, -5, 4);
  turncamera(0, 0);
  nullvector(v0);
  addlight(v0);
  if str2='1' then addlight(v0);
  copyvector(light[1], camera.direction);
  copyvector(light[2], camera.direction);
  if str2='1' then setcoloredmaterials
  else if str2='2' then settexturedmaterials
  else if str2='3' then setwhitematerials
  else if str2='4' then setwhitebumpmaterials;
  if str1='1' then createcube
  else if str1='2' then createasymmetriccube
  else if str1='3' then createstrangecube;
  CubePrepare;
end;

procedure TForm1.FormKeyPress;
begin
  PrerareToKey;
  with camera do
     case key of
        'a': begin a:=-0.5; copyvector(v, up); end;
        'd': begin a:=0.5; copyvector(v, up); end;
        'w': begin a:=-0.5; vectorproduct(direction, up, v); normalizevector(v); end;
        's': begin a:=0.5; vectorproduct(direction, up, v); normalizevector(v); end;
        '1': if tb=-1 then begin n:=1; tb:=0; sign:=1; inc(steps); ret[steps][1]:=n; ret[steps][2]:=1; end;
        '2': if tb=-1 then begin n:=2; tb:=0; sign:=1; inc(steps); ret[steps][1]:=n; ret[steps][2]:=1; end;
        '3': if tb=-1 then begin n:=3; tb:=0; sign:=1; inc(steps); ret[steps][1]:=n; ret[steps][2]:=1; end;
        '4': if tb=-1 then begin n:=4; tb:=0; sign:=1; inc(steps); ret[steps][1]:=n; ret[steps][2]:=1; end;
        '5': if tb=-1 then begin n:=5; tb:=0; sign:=1; inc(steps); ret[steps][1]:=n; ret[steps][2]:=1; end;
        '6': if tb=-1 then begin n:=6; tb:=0; sign:=1; inc(steps); ret[steps][1]:=n; ret[steps][2]:=1; end;
        'r': if (tb=-1) and (steps>0) then begin n:=ret[steps][1]; sign:=-ret[steps][2]; dec(steps); returning:=true; tb:=0; end;
        'm': if tb=-1 then mix(random(100));
        'z': if (tb=-1) and (steps>0) then begin n:=ret[steps][1]; sign:=-ret[steps][2]; dec(steps); tb:=0; end;
     end;
  PostKey;
end;

procedure TForm1.FormMouseMove;
begin
 if (Shift=[ssRight]) or (Shift=[ssLeft])  then  PrerareToKey;
 if Shift=[ssRight] then turncamera(mx-x, y-my);
  //begin

    mx:=x; my:=y;
 // end;
 if Shift=[ssLeft] then
   begin
    if tb=-1 then
    begin
      rubics1.x := x;
      rubics1.y := y;
      l:=getundermouse(ci, cj, ck);
      if  ((ci<>ci0) or (cj<>cj0) or (ck<>ck0)) then processcursor;
      ci0:=ci; cj0:=cj; ck0:=ck;
    end;
   end;
 if (Shift=[ssRight]) or (Shift=[ssLeft])  then PostKey;
end;

end.
