program Rubic;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  rubics1 in 'rubics1.pas',
  PRIMITIV in 'PRIMITIV.PAS',
  GRAPH3D in 'GRAPH3D.PAS',
  logical in 'logical.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
