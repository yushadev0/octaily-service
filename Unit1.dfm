object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Octaily Service - by YG'
  ClientHeight = 511
  ClientWidth = 671
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 473
    Height = 503
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object btnStartServer: TButton
    Left = 496
    Top = 416
    Width = 155
    Height = 25
    Caption = 'Sunucuyu Ba'#351'lat'
    TabOrder = 1
    OnClick = btnStartServerClick
  end
  object Button1: TButton
    Left = 496
    Top = 385
    Width = 155
    Height = 25
    Caption = 'G'#252'n'#252'n Sonu'#231'lar'#305'n'#305' Getir'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 496
    Top = 447
    Width = 155
    Height = 25
    Caption = 'Sunucuyu Durdur'
    TabOrder = 3
    OnClick = Button2Click
  end
end
