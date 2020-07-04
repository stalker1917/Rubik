unit logical;

interface
uses useful,math,System.Threading;

const
Depth = 14;  //Максимально тянет 12 ходов

type
TRubikData = array[1..6,1..8] of byte;

TOneHistory  = Array[1..Depth] of byte;
THistory = Array[0..3] of TOneHistory; //4 -никуда не ходить.

TRubik = class
  Fname : String;
  Data  : TRubikData;
  Score : Integer;
  Pointers : array[0..6] of PMaterial;
  Function GetPosition(i,j:ShortInt):Byte;
  Function GetMaterial(Side,i,j,k:ShortInt):PMaterial;
  Procedure LoadRubik;
  Procedure SaveRubik;
  Procedure TurnedRubik(P1,P2:Byte;F,N:Integer;NThread : Integer);    //F-какую сторону выбрали фронтальной.
  Function  OneThreadRubik(P1,P2:Byte;F,NThread,CurrDepth,LastTurn:Integer):TOneHistory;
  Procedure  ThreadCycle(NThread:Integer);
  Function  GetScore:Integer;
  procedure Solve;
  Constructor Create;
  Constructor CreateReduct;
  Destructor  Destroy;
end;

TSolve = Array[0..3,0..1,1..Depth+1] {of array of } of TRubik;


var
Rubik,Rubik2 : TRubik;
Solves : TSolve;
ThreadBuf : Array[0..3] of TRubik;
History : THistory;
Decode : Array[0..1,0..3] of String = (('D','D"','Y','Y"'),('U','U"','y','y"'));
Forwstr : Array[0..3] of String = ('F=orange','F=green','F=red','F=blue');
DStrings : Array[0..4] of String;

procedure LTurn(var Dest,Source:TRubikData;s0,r:Byte);
procedure YTurn(var Dest,Source:TRubikData;F,Up,Left:Byte);     //s0 - нижний или верхний поворот

implementation

Procedure TRubik.LoadRubik;
var i,j:Integer;
T:Text;
begin
  assignFile(T,Fname);
  Reset(t);
  for I := Low(Data) to High(Data) do
    for j := Low(Data[i]) to High(Data[i]) do
      if j=High(Data[i]) then Readln(T,Data[i,j])
                         else Read(T,Data[i,j]);
  CloseFile(T);
end;

Procedure TRubik.SaveRubik;
var i,j:Integer;
T:Text;
begin
  assignFile(T,Fname);
  Rewrite(t);
  for I := Low(Data) to High(Data) do
    for j := Low(Data[i]) to High(Data[i]) do
      if j=High(Data[i]) then Writeln(T,Data[i,j])
                         else Write(T,Data[i,j]);
  CloseFile(T);
end;
Constructor TRubik.Create;
var
i,j: Integer;
begin
  Pointers[0] :=@mat;
  Pointers[1] :=@white;
  Pointers[2] :=@orange;
  Pointers[3] :=@green;
  Pointers[4] :=@red;
  Pointers[5] :=@blue;
  Pointers[6] :=@yellow;
for i:=1 to 8 do
   for j:=1 to 6 do
     Data[j,i]:=j;
end;

Constructor TRubik.CreateReduct;
begin
  inherited Create;
end;


function TRubik.GetPosition;
begin
  case j of
    -1: result := i+2;
    0:
      if i=0 then result := 0
             else result:=6-2*i;
    1: result :=6-i;
  end;
end;

function TRubik.GetMaterial;
var
Pos:Integer;
begin
   case Side of
     1: Pos := GetPosition(i,-j);
     2: Pos := GetPosition(k,-j);
     3: Pos := GetPosition(k,i);
     4: Pos := GetPosition(k,j);
     5: Pos := GetPosition(k,-i);
     6: Pos := GetPosition(-i,-j);
   end;
 if Pos=0 then result:=Pointers[Side]
          else result:=Pointers[Data[Side,Pos]];
end;


Procedure TRubik.TurnedRubik;
begin
  //result := TRubik.CreateReduct;
  if N<2 then   //Поворот вверх или вниз
    LTurn(ThreadBuf[NThread].Data,Data,P1*5+1,N)
  else
    YTurn(ThreadBuf[NThread].Data,Data,F,P2,N-2);
  Data := ThreadBuf[NThread].Data;
end;

Function TRubik.OneThreadRubik;  //Потоковая процедура.
var i{,j,k}:Integer;
//Buf1:TRubik;
//Cycles,Index:Integer;
TekHistory:TOneHistory;
begin
    Solves[NThread,1,CurrDepth].Data := Data;
    Solves[NThread,1,CurrDepth].GetScore;
    //TekHistory := 4;
    result[CurrDepth]:=4;  //+20% на запись History
    for I := 0 to 3 do
      begin
        if (i mod 2 <> Lastturn mod 2) and (i div 2 = Lastturn div 2) then continue;// Нельзя отменять последний ход.
        Solves[NThread,0,CurrDepth+1].Data := Data;
        Solves[NThread,0,CurrDepth+1].TurnedRubik(P1,P2,F,i,NThread);
        if CurrDepth<Depth then TekHistory := Solves[NThread,0,CurrDepth+1].OneThreadRubik(P1,P2,F,NThread,CurrDepth+1,i);
        if Solves[NThread,0,CurrDepth+1].GetScore>Solves[NThread,1,CurrDepth].Score then     //Надо обновлять и Score!
          begin
            Solves[NThread,1,CurrDepth].Data := Solves[NThread,0,CurrDepth+1].Data;
            Solves[NThread,1,CurrDepth].Score := Solves[NThread,0,CurrDepth+1].Score;
            //History[NThread,CurrDepth]:=i;
            result := TekHistory;
            result[CurrDepth] := i;
          end;
      end;
    Data := Solves[NThread,1,CurrDepth].Data;
    //History[NThread,CurrDepth] := TekHistory;
end;

procedure DecodeString(Nthread,P1,P2:Integer);
var k:Integer;
begin
   DStrings[NThread] :='';
   for k := Low(History[NThread]) to High(History[NThread]) do
    if (History[NThread,k]<4) then
      if History[NThread,k]<2 then  DStrings[NThread]:=DStrings[NThread] + Decode[P1,History[NThread,k]]+' '
                              else  DStrings[NThread]:=DStrings[NThread] + Decode[P2,History[NThread,k]]+' '
    else break;
end;

Procedure TRubik.ThreadCycle;
var i,j,k,l,m:Integer;
Buf1:TRubik;
Cycles :Integer;
TekHistory:TOneHistory;
begin
   Buf1 := TRubik.CreateReduct;
   Buf1.Score :=0;
   Buf1.Data := Data;
   History[NThread,1] := NThread;
   for I := 0 to 3 do
    for j := 0 to 1 do
      for k := 0 to 1 do
        begin
          Solves[NThread,0,1].Data := Data;
          Solves[NThread,0,1].TurnedRubik(j,k,i,NThread,NThread);
          TekHistory := Solves[NThread,0,1].OneThreadRubik(j,k,i,NThread,2,NThread);
          TekHistory[1] := NThread;
          if Solves[NThread,0,1].GetScore>Buf1.GetScore then
          begin
            Buf1.Data := Solves[NThread,0,1].Data;
            History[NThread] := TekHistory;
            DecodeString(NThread,j,k);
            DStrings[NThread] := Forwstr[i]+' '+DStrings[NThread];
            //Декодируем строку History
          end;
        end;
  Data := Buf1.Data;
end;

Function TRubik.GetScore;
var i,j:Integer;
  begin
   Score:=0;
    if (Data[1,1]=1) and (Data[2,3]=2) then Score:=Score+20;
    if (Data[1,8]=1) and (Data[2,4]=2) then Score:=Score+30;
    if (Data[1,7]=1) and (Data[2,5]=2) then Score:=Score+20;
    if (Data[1,2]=1) and (Data[5,4]=5) then Score:=Score+30;
    if (Data[1,3]=1) and (Data[5,3]=5) then Score:=Score+20;
    if (Data[1,4]=1) and (Data[4,4]=4) then Score:=Score+30;
    if (Data[1,5]=1) and (Data[4,3]=4) then Score:=Score+20;
    if (Data[1,6]=1) and (Data[3,4]=3) then Score:=Score+30;
    if (Data[2,1]=2) and (Data[5,7]=5) then Score:=Score+2;
    if (Data[2,2]=2) and (Data[5,6]=5) then Score:=Score+3*3;
    if (Data[2,7]=2) and (Data[3,1]=3) then Score:=Score+2;
    if (Data[2,6]=2) and (Data[3,2]=3) then Score:=Score+3*3;
    if (Data[2,8]=2) and (Data[6,4]=6) then Score:=Score+3;
    if (Data[3,7]=3) and (Data[4,1]=4) then Score:=Score+2;
    if (Data[3,6]=3) and (Data[4,2]=4) then Score:=Score+3*3;
    if (Data[3,8]=3) and (Data[6,6]=6) then Score:=Score+3;
    if (Data[4,7]=4) and (Data[5,1]=5) then Score:=Score+2;
    if (Data[4,6]=4) and (Data[5,2]=5) then Score:=Score+3*3;
    if (Data[4,8]=4) and (Data[6,8]=6) then Score:=Score+3;
    if (Data[5,8]=5) and (Data[6,2]=6) then Score:=Score+3;
   Result:=Score;
  end;

procedure TRubik.Solve;
var Buf1: array[0..4] of TRubik;
i,j,k,l,m:Integer;
Pwr:Integer;
begin
 // MaxHistory[4,1] := 4;// Ничего не делаем.
  DStrings[4]:='';
  for I := 0 to 4 do
    begin
      Buf1[i] := TRubik.CreateReduct;
      Buf1[i].Data := Data;
      if i<4 then ThreadBuf[i] := TRubik.CreateReduct;
      if i<4 then
      for j := 0 to 1 do
        for k := 1 to High(Solves[i,j]) do
          Solves[i,j,k] := TRubik.CreateReduct;
    end;

   //exit;
  TParallel.For(0,3,procedure(l: integer)
  //for l := 0 to 3 do
  begin
    Buf1[l].ThreadCycle(l);
  end
 // ;
  );
  for i := 0 to 3 do
     begin
         if Buf1[i].GetScore>Buf1[4].GetScore then
         begin
           Buf1[4].Data := Buf1[i].Data;
           DStrings[4] := DStrings[i];
         end;
        // Buf1[i].Destroy;
     end;
  Data := Buf1[4].Data;
  //Buf1[4].Destroy;

 // Rubik2 := Self;
  //if Buf1<>nil then Buf1.Destroy;
end;

Destructor TRubik.Destroy;
begin
  inherited Destroy;
end;


procedure LTurn(var Dest,Source:TRubikData;s0,r:Byte);           //Число- какого цвевета поворачивать 1- по часовой стрелки 0- против.  s1-верх s4-прав
var i,j:Integer;
 begin
  Dest:=Source;
  if r=0 then
   begin
    Dest[s0,1]:=Source[s0,7];
    Dest[s0,2]:=Source[s0,8];
    for i:=1 to 6 do
     Dest[s0,i+2]:=Source[s0,i];
    case s0 of
     1:
     for j:=1 to 3 do
      begin
       Dest[2,j+2]:=Source[3,j+2];
       Dest[3,j+2]:=Source[4,j+2];
       Dest[4,j+2]:=Source[5,j+2];
       Dest[5,j+2]:=Source[2,j+2];
      end;
     2:
      for j:=1 to 3 do
      begin
       Dest[1,(5+j) mod 8 +1]:=Source[5,j+4];
       Dest[3,j]:=Source[1,(5+j) mod 8 +1];
       Dest[5,j+4]:=Source[6,j+2];
       Dest[6,j+2]:=Source[3,j];
      end;
     3:
      for j:=1 to 3 do
      begin
       Dest[1,j+4]:=Source[2,j+4];
       Dest[2,j+4]:=Source[6,j+4];
       Dest[4,j]:=Source[1,j+4];
       Dest[6,j+4]:=Source[4,j];
      end;
     4:
      for j:=1 to 3 do
      begin
       Dest[1,j+2]:=Source[3,j+4];
       Dest[3,j+4]:=Source[6,(5+j) mod 8 +1];
       Dest[5,j]:=Source[1,j+2];
       Dest[6,(5+j) mod 8 +1]:=Source[5,j];
      end;
     5:
      for j:=1 to 3 do
      begin
       Dest[1,j]:=Source[4,4+j];
       Dest[2,j]:=Source[1,j];
       Dest[4,4+j]:=Source[6,j];
       Dest[6,j]:=Source[2,j];
      end;
     6:
      for j:=1 to 3 do
      begin
       Dest[2,(9-j) mod 8 +1]:=Source[5,(9-j) mod 8 +1];
       Dest[3,(9-j) mod 8 +1]:=Source[2,(9-j) mod 8 +1];
       Dest[4,(9-j) mod 8 +1]:=Source[3,(9-j) mod 8 +1];
       Dest[5,(9-j) mod 8 +1]:=Source[4,(9-j) mod 8 +1];
      end;
    end;
   end
  else
   begin
    Dest[s0,7]:=Source[s0,1];
    Dest[s0,8]:=Source[s0,2];
    for i:=1 to 6 do
     Dest[s0,i]:=Source[s0,i+2];
    case s0 of
     1:
     for j:=1 to 3 do
      begin
       Dest[2,j+2]:=Source[5,j+2];
       Dest[3,j+2]:=Source[2,j+2];
       Dest[4,j+2]:=Source[3,j+2];
       Dest[5,j+2]:=Source[4,j+2];
      end;
     2:
      for j:=1 to 3 do
      begin
       Dest[1,(5+j) mod 8 +1]:=Source[3,j];
       Dest[3,j]:=Source[6,j+2];
       Dest[5,j+4]:=Source[1,(5+j) mod 8 +1];
       Dest[6,j+2]:=Source[5,j+4];
      end;
     3:
      for j:=1 to 3 do
      begin
       Dest[1,j+4]:=Source[4,j];
       Dest[2,j+4]:=Source[1,j+4];
       Dest[4,j]:=Source[6,j+4];
       Dest[6,j+4]:=Source[2,j+4];
      end;
     4:
      for j:=1 to 3 do
      begin
       Dest[1,j+2]:=Source[5,j];
       Dest[3,j+4]:=Source[1,j+2];
       Dest[5,j]:=Source[6,(5+j) mod 8 +1];
       Dest[6,(5+j) mod 8 +1]:=Source[3,j+4];
      end;
     5:
      for j:=1 to 3 do
      begin
       Dest[1,j]:=Source[2,j];
       Dest[2,j]:=Source[6,j];
       Dest[4,4+j]:=Source[1,j];
       Dest[6,j]:=Source[4,4+j];
      end;
     6:
      for j:=1 to 3 do
      begin
       Dest[2,(9-j) mod 8 +1]:=Source[3,(9-j) mod 8 +1];
       Dest[3,(9-j) mod 8 +1]:=Source[4,(9-j) mod 8 +1];
       Dest[4,(9-j) mod 8 +1]:=Source[5,(9-j) mod 8 +1];
       Dest[5,(9-j) mod 8 +1]:=Source[2,(9-j) mod 8 +1];
      end;
    end;
   end;
 end;

procedure Y1Turn(var Dest,Source:TRubikData;Turn,F,Up,Left:Byte);
var Clock:Byte;
Right : Byte;
begin
  Clock := Up;
  if (Turn div 2)=(Turn mod 2) then Clock := Clock xor 1;
  Clock := Clock xor Left;
  Right := (Turn+1) mod 2;
  Right := Right xor Left;
  F := (F+Right) mod 4 +2;
  LTurn(Dest,Source,F,Clock);

  //Когда Left то Turn mod 2

end;

procedure YTurn;
var Buf1,Buf2:TRubikData;
  I: Integer;
begin
  Buf1 := Source;  //Идёт ли копирование массивов
  for I := 0 to 3 do
    begin
      Y1Turn(Buf2,Buf1,i,f,Up,Left);
      Buf1 := Buf2;
    end;
  Dest:=Buf2;
end;




end.
