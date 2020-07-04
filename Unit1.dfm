object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Rukik Cube. Y-Move Method. Beta version(0.70)'
  ClientHeight = 480
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnMouseMove = FormMouseMove
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 557
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 557
    Top = 39
    Width = 75
    Height = 25
    Caption = 'Solve'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 557
    Top = 70
    Width = 60
    Height = 21
    TabOrder = 2
  end
  object Memo1: TMemo
    Left = 22
    Top = 417
    Width = 595
    Height = 55
    TabOrder = 3
  end
end
