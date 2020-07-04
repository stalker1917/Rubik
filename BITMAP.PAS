unit bitmap;

{$A-}
interface

const
  maxbitmapsize=16384;

type
  tbitmap =  array {[0..maxbitmapsize-1]} of byte;
  tpalette = array [0..767] of byte;
  bmFileHeader = record  {заголовок файла}
    Typf: word;        {сигнатура }
    Size: longint;     {длина файла в байтах}
    Res1: word;        {зарезервировано}
    Res2: word;        {зарезервировано}
    OfBm: longint;     {смещение изображения в байтах (1078)}
    end;
  bmInfoHeader = record   {информационный заголовок}
    Size: longint;       {длина заголовка в байтах (40)}
    Widt: longint;       {ширина изображения (в точках)}
    Heig: longint;       {высота изображения (в точках)}
    Plan: word;          {число плоскостей (1)}
    BitC: word;          {глубина цвета (бит на точку) (8)}
    Comp: longint;       {тип компрессии (0 - нет)}
    SizI: longint;       {размер изображения в байтах}
    XppM: longint;       {горизонтальное разрешение}
    YppM: longint;       {вертикальное разрешение}
    NCoL: longint;       {число цветов}
    NCoI: longint;       {число основных цветов}
    end;
  bmHeader = record       {полный заголовок файла}
    fh: bmFileHeader;     {заголовок файла}
    ih: bmInfoHeader;     {информационный заголовок}
    palette: array [0..255, 0..3] of byte; {таблица палитры}
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
    p[i*3+2]:=h.palette[i,0] shr 2; {синий}
    p[i*3+1]:=h.palette[i,1] shr 2; {зеленый}
    p[i*3+0]:=h.palette[i,2] shr 2; {красный}
  end;
end;

end.