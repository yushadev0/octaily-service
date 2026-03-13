object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Octaily Service - by YG'
  ClientHeight = 511
  ClientWidth = 971
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
    Left = 744
    Top = 432
    Width = 155
    Height = 25
    Caption = 'Sunucuyu ba'#351'lat'
    TabOrder = 1
    OnClick = btnStartServerClick
  end
end
