<GameFile>
  <PropertyGroup Name="simple_msgbox" Type="Layer" ID="wgjq7sanvmc8fp94ikh5zl0d-brxyo123u6e" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.000000">
      </Animation>
      <ObjectData Name="Layer" ctype="GameNodeObjectData">
        <Size X="640.000000" Y="1136.000000" />
        <Children>
          <AbstractNodeData Name="bg" ActionTag="-542347201" Tag="135" RotationSkewX="0" RotationSkewY="0" LeftMargin="44.999901" RightMargin="45.000099" TopMargin="410.499908" BottomMargin="410.500092" TouchEnable="True" LeftEage="56" RightEage="56" TopEage="50" BottomEage="50" Scale9OriginX="56" Scale9OriginY="50" Scale9Width="8" Scale9Height="20" Scale9Enable="True" ctype="ImageViewObjectData">
            <Size Y="315" X="550" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="319.999908" Y="568.000122" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="login/box_bg.png" Plist="login.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="close1_btn" ActionTag="2130682687" Tag="136" RotationSkewX="0" RotationSkewY="0" LeftMargin="521.999023" RightMargin="48.000999" TopMargin="410" BottomMargin="664" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="70" Scale9Height="62" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
            <Size Y="62" X="70" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="556.999023" Y="695" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <NormalFileData Type="PlistSubImage" Path="login/close1_normal.png" Plist="login.plist" />
            <PressedFileData Type="PlistSubImage" Path="login/close1_press.png" Plist="login.plist" />
            <DisabledFileData Type="PlistSubImage" Path="login/close1_press.png" Plist="login.plist" />
            <TextColor A="255" B="70" G="65" R="65" />
            <OutlineColor />
            <FontResource />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="title" ActionTag="767663476" Tag="137" RotationSkewX="0" RotationSkewY="0" LeftMargin="213.499802" RightMargin="213.500198" TopMargin="388.50061" BottomMargin="674.49939" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="256" Scale9Height="74" ctype="ImageViewObjectData">
            <Size Y="73" X="213" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="319.999786" Y="710.99939" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="login/paper_bg1.png" Plist="login.plist" />
            <Children>
              <AbstractNodeData Name="name" ActionTag="-1459182734" Tag="138" RotationSkewX="0" RotationSkewY="0" LeftMargin="50" RightMargin="48" TopMargin="18.000099" BottomMargin="24.999901" FontSize="28" LabelText="$$$版本过低" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="30" X="148" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="106" Y="39.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="0" G="0" R="0" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="name_2" ActionTag="1114804698" Tag="85" RotationSkewX="0" RotationSkewY="0" LeftMargin="32.000099" RightMargin="29.999901" TopMargin="17.3333" BottomMargin="25.6667" FontSize="28" LabelText="血钻不足" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="30" X="112" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="106.000099" Y="40.666698" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="0" G="0" R="0" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="desc_2" ActionTag="1325295760" Tag="86" RotationSkewX="0" RotationSkewY="0" LeftMargin="104" RightMargin="98" TopMargin="485" BottomMargin="551" FontSize="24" LabelText="你的血钻数量不足，是否前往储值？" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
            <Size Y="100" X="438" />
            <AnchorPoint ScaleX="0" ScaleY="1" />
            <Position X="104" Y="651" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <OutlineColor />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="desc" ActionTag="-1474487811" Tag="139" RotationSkewX="0" RotationSkewY="0" LeftMargin="101.000198" RightMargin="100.999802" TopMargin="484.000885" BottomMargin="551.999084" FontSize="24" LabelText="$$$你当前的游戏版本过低，游戏将关闭。" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
            <Size Y="100" X="438" />
            <AnchorPoint ScaleX="0" ScaleY="1" />
            <Position X="101.000198" Y="651.999084" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <OutlineColor />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="confirm_btn" ActionTag="-1088152227" Tag="140" RotationSkewX="0" RotationSkewY="0" LeftMargin="331.5" RightMargin="103.5" TopMargin="612.999878" BottomMargin="457.000092" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="278" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="确 认" FontSize="28" ctype="ButtonObjectData">
            <Size Y="66" X="205" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="434" Y="490.000092" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <NormalFileData Type="PlistSubImage" Path="login/buttonbg_3.png" Plist="login.plist" />
            <PressedFileData Type="PlistSubImage" Path="login/buttonbg_3.png" Plist="login.plist" />
            <DisabledFileData Type="PlistSubImage" Path="login/buttonbg_3.png" Plist="login.plist" />
            <TextColor A="255" B="0" G="0" R="0" />
            <OutlineColor />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="close2_btn" ActionTag="-2079435283" Tag="141" RotationSkewX="0" RotationSkewY="0" LeftMargin="102.500198" RightMargin="332.499786" TopMargin="613.000183" BottomMargin="456.999786" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="278" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="关 闭" FontSize="28" ctype="ButtonObjectData">
            <Size Y="66" X="205" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="205.000198" Y="489.999786" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <NormalFileData Type="PlistSubImage" Path="login/buttonbg_2.png" Plist="login.plist" />
            <PressedFileData Type="PlistSubImage" Path="login/buttonbg_2.png" Plist="login.plist" />
            <DisabledFileData Type="PlistSubImage" Path="login/buttonbg_2.png" Plist="login.plist" />
            <TextColor A="255" B="0" G="0" R="0" />
            <OutlineColor />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <ShadowColor />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>
