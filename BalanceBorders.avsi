#��������:
  #------------------------------------------------------------------------------------------------------------------------------
  # function BalanceBorders(clip c, int cTop, int cBottom, int cLeft, int cRight, int "thresh", int "blur")
  #
  # //by PL � [2009.09.25] v0.2 :)
  #
  # ������� �������� �������� ������� �������� ����� ���, ����� ��� ���� "����� ������" �� ��������,
  # ���, ��������, �������� �������� "��������" ������������� Crop() ��� �������� "���������� ����",
  # �� ����� ������ ������������ �� "���������" �����������. ��. ������� �������.
  #------------------------------------------------------------------------------------------------------------------------------

#���������:
  #------------------------------------------------------------------------------------------------------------------------------
  # � - ����� YV12 ����. ������� ����������� "� ��������" � �������� ��������� �� ����������.
  #
  # cTop, cBottom, cLeft, cRight - range[0..inf]
  #   ���������� ���������� �������� � ������ �������.
  #   �� �������� ������ ����� ���������, ���� ������� ��������,
  #   ������ ������������ � ����� ������ ��������,
  #   ��, ��� ���������� �������� ����������, "����� �� ����"...
  #
  # "thresh" - range[0..128] default[128] recommended[0..16 ��� 128]
  #   ����� ���������� ��������� ��� ���������� ������� �����.
  #
  # "blur" - range[1..inf] default[999] recommended[1..20 ��� 999]
  #   ������� �������� ��� ���������� ������� ������,
  #   ������� �������� ���� ����� ������ ������������ ������,
  #   ������� �������� ���� ����� ������ �������� �������.
  #-------------------------------------------------------------------------------------------------------------------------------

#������:
  #-------------------------------------------------------------------------------------------------------------------------------
  # 1)��� ��������� �� ��������� thresh=128 blur=999 �� �������� ���� ��������,
  #   ���������� ������ �������� ����� ��� ������� ���� �������, ��� ���������� �������,
  #   �.�. ����� �������� �������� ����� ������ ��������� � ��������� ������,
  #   �� ��� ���� �� ��������� ��������� ��������� �������.
  #   � ��� thresh=128 � blur=1 �� �������� ����������� ���������� ���� ��������,
  #   �.�. ����� ����� ���� ����� ��������� ���������, �� ������������ ������� ����������.
  #
  # 2)������������� ������������� �������� ���������� �������� ��� ��������� � ��������� � ������� ������� "thresh", � ��������� "blur"
  #   ��� ����� �������� � ��������� ������������� ���������� "�� ������ �����".
  #   ���������� ��� ������� ������ ������� ���������� ��� ����� ������� ���������� �������� ��� ��������� �
  #   ��� ����� ������� �������� ������ "thresh" (��� ������������� blur 0..16).
  #-------------------------------------------------------------------------------------------------------------------------------

#�������:
  #-------------------------------------------------------------------------------------------------------------------------------
  #   ���������� ����������� ������� �� ���� ������� (���������� ���������� ��������, �����������, ������� ��� �������):
  #   BalanceBorders(7,6,4,4)
  #   BalanceBorders(7,6,4,4, thresh=4,blur=10)
  #
  #   ������� ���������� ������� �����:
  #   BalanceBorders(7,6,4,4)                      //"�����" ������ ������
  #   BalanceBorders(5,5,4,4, thresh=2,   blur=10) //������ ����-���� �������� ������� ������� (� "�������")
  #   BalanceBorders(3,3,2,2, thresh=8,   blur=4)  //�������� �������� "�������� ���������� �������"
  #   BalanceBorders(1,1,0,0, thresh=128, blur=1)  //�������� ������� � ������ ������ �������� (��� �������� "������ �����")
  #-------------------------------------------------------------------------------------------------------------------------------

function BalanceBorders(clip c, int cTop, int cBottom, int cLeft, int cRight, int "thresh", int "blur")
{
    Assert(isYV12(c), "This is not an YV12 clip. Convert color space to YV12 before using BalanceBorders().")

    thresh = Default(thresh, 128)
    blur   = Default(blur,   999)

    Assert(blur   > 0, "Blur parameter in BalanceBorders() must be > 0")
    Assert(thresh > 0, "Thresh parameter in BalanceBorders() must be > 0")

    c
    cTop    >0 ? BalanceTopBorder(cTop,    thresh, blur).TurnRight() : last.TurnRight()
    cLeft   >0 ? BalanceTopBorder(cLeft,   thresh, blur).TurnRight() : last.TurnRight()
    cBottom >0 ? BalanceTopBorder(cBottom, thresh, blur).TurnRight() : last.TurnRight()
    cRight  >0 ? BalanceTopBorder(cRight,  thresh, blur).TurnRight() : last.TurnRight()
}

function BalanceTopBorder(clip c, int cTop, int "thresh", int "blur")
{
    cWidth = c.width
    cHeight = c.height
    cTop = min(cTop,cHeight-1)
    blurWidth = max(4,floor(cWidth/blur))

    c2 = c.PointResize(cWidth*2,cHeight*2)

    c2.\
    Crop(0,cTop*2,cWidth*2,2)
    PointResize(cWidth*2,cTop*2)
    BilinearResize(blurWidth*2,cTop*2)
    mt_convolution("1 1 1","0 1 0",y=3,u=3,v=3)
    BilinearResize(cWidth*2,cTop*2)
    referenceBlur = last

    original = c2.Crop(0,0,cWidth*2,cTop*2)

    original
    BilinearResize(blurWidth*2,cTop*2)
    mt_convolution("1 1 1","0 1 0",y=3,u=3,v=3)
    BilinearResize(cWidth*2,cTop*2)
    originalBlur = last

    balanced = mt_lutXYZ(original,originalBlur,referenceBlur,"z y - x +",y=3,u=3,v=3)
    difference = mt_makeDiff(balanced,original,y=3,u=3,v=3)

    tp = string(128+thresh)
    tm = string(128-thresh)
    difference = difference.mt_lut("x "+tp+" > "+tp+" x ?",y=3,u=3,v=3)
    difference = difference.mt_lut("x "+tm+" < "+tm+" x ?",y=3,u=3,v=3)

    mt_addDiff(original,difference,y=3,u=3,v=3)

    StackVertical(last,c2.Crop(0,cTop*2,cWidth*2,(cHeight-cTop)*2)).PointResize(cWidth,cHeight)
}