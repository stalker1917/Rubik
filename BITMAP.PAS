unit bitmap;

{$A-}
interface

const
  maxbitmapsize=16384;

type
  tbitmap =  array {[0..maxbitmapsize-1]} of byte;
  tpalette = array [0..767] of byte;
  bmFileHeader = record  {��������� �����}
    Typf: word;        {��������� }
    Size: longint;     {����� ����� � ������}
    Res1: word;        {���������������}
    Res2: word;        {���������������}
    OfBm: longint;     {�������� ����������� � ������ (1078)}
    end;
  bmInfoHeader = record   {�������������� ���������}
    Size: longint;       {����� ��������� � ������ (40)}
    Widt: longint;       {������ ����������� (� ������)}
    Heig: longint;       {������ ����������� (� ������)}
    Plan: word;          {����� ���������� (1)}
    BitC: word;          {������� ����� (��� �� �����) (8)}
    Comp: longint;       {��� ���������� (0 - ���)}
    SizI: longint;       {������ ����������� � ������}
    XppM: longint;       {�������������� ����������}
    YppM: longint;       {������������ ����������}
    NCoL: longint;       {����� ������}
    NCoI: longint;       {����� �������� ������}
    end;
  bmHeader = record       {������ ��������� �����}
    fh: bmFileHeader;     {��������� �����}
    ih: bmInfoHeader;     {�������������� ���������}
    palette: array [0..255, 0..3] of byte; {������� �������}
    end;

procedure bmpload(var b: tbitmap; var w: byte; var p: tpalette; n: string);


implementation

procedure bmpload(var b: tbitmap; var w: byte; var p: tpalette; n: string);
var
  h: bmHeader;
  i: integer;
  //t: byte;
  f: file of byte;
begin
  assign(f, n);
  reset(f);
  blockread(f, h, sizeof(h));
  SetLength(b,h.ih.sizi);//getmem(b, h.ih.sizi);
  w:=h.ih.widt;
  for i:=h.ih.heig-1 downto 0 do
  begin
    blockread(f, b[i*h.ih.widt], h.ih.widt);
  end;
  close(f);
  for i:=0 to 255 do
  begin
    p[i*3+2]:=h.palette[i,0] shr 2; {�����}
    p[i*3+1]:=h.palette[i,1] shr 2; {�������}
    p[i*3+0]:=h.palette[i,2] shr 2; {�������}
  end;
end;

end.