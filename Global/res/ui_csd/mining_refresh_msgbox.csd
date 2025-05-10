<GameFile>
  <PropertyGroup Name="mining_refresh_msgbox" Type="Layer" ID="nts06-qr9xhkdcue3v2oyfaj1ibgzm8wl4p7" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.000000">
      </Animation>
      <ObjectData Name="Layer" ctype="GameNodeObjectData">
        <Size X="640.000000" Y="1136.000000" />
        <Children>
          <AbstractNodeData Name="bg" ActionTag="-703175741" Tag="256" RotationSkewX="0" RotationSkewY="0" LeftMargin="11" RightMargin="11" TopMargin="165.5" BottomMargin="165.5" LeftEage="50" RightEage="50" TopEage="56" BottomEage="56" Scale9OriginX="50" Scale9OriginY="56" Scale9Width="20" Scale9Height="8" Scale9Enable="True" ctype="ImageViewObjectData">
            <Size Y="805" X="618" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="568" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/box_bg.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="border" ActionTag="-1951655116" Tag="258" RotationSkewX="-90" RotationSkewY="-90" LeftMargin="317.999115" RightMargin="314.000885" TopMargin="133.999298" BottomMargin="460.000702" Alpha="153" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="2" Scale9Height="108" ctype="ImageViewObjectData">
            <Size Y="542" X="8" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="321.999115" Y="731.000671" />
            <Scale ScaleX="-1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/herodetail_apart_d_h462.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="title_bg" ActionTag="1728954571" Tag="259" RotationSkewX="0" RotationSkewY="0" LeftMargin="192" RightMargin="192" TopMargin="147.999893" BottomMargin="914.000122" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="256" Scale9Height="74" ctype="ImageViewObjectData">
            <Size Y="74" X="256" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="951.000122" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/paper_bg1.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="title" ActionTag="-1251164413" Tag="260" RotationSkewX="0" RotationSkewY="0" LeftMargin="224.000397" RightMargin="223.999603" TopMargin="163.4991" BottomMargin="937.500916" FontSize="32" LabelText="等级重置" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
            <Size Y="35" X="128" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320.000397" Y="955.000916" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="11" G="53" R="63" />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <OutlineColor />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="desc" ActionTag="1929438105" Tag="261" RotationSkewX="0" RotationSkewY="0" LeftMargin="74.214699" RightMargin="66.785301" TopMargin="226.856094" BottomMargin="807.143921" FontSize="24" LabelText="$$$矿区每两天可以重置一次巨魔等级，满足对应条件可以消耗资源重置到指定的巨魔等级。距离下一次重置还有：19:00:00。" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
            <Size Y="102" X="499" />
            <AnchorPoint ScaleX="0" ScaleY="1" />
            <Position X="74.214699" Y="909.143921" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="109" G="167" R="194" />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <OutlineColor />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="close_btn" ActionTag="-23680874" Tag="266" RotationSkewX="0" RotationSkewY="0" LeftMargin="556.817383" RightMargin="13.1826" TopMargin="165.090103" BottomMargin="908.909912" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="70" Scale9Height="62" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
            <Size Y="62" X="70" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="591.817383" Y="939.909912" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <NormalFileData Type="PlistSubImage" Path="button/close1_normal.png" Plist="ui.plist" />
            <PressedFileData Type="PlistSubImage" Path="button/close1_press.png" Plist="ui.plist" />
            <DisabledFileData Type="PlistSubImage" Path="button/close1_press.png" Plist="ui.plist" />
            <TextColor A="255" B="70" G="65" R="65" />
            <OutlineColor />
            <FontResource />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="reset_list" ActionTag="-1136955842" Tag="621" RotationSkewX="0" RotationSkewY="0" LeftMargin="50.780399" RightMargin="39.219601" TopMargin="408.069092" BottomMargin="201.930893" TouchEnable="True" VerticalEdge="TopEdge" BackColorAlpha="102" IsBounceEnabled="True" ScrollDirectionType="Horizontal" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="1" Scale9Height="0" ClipAble="True" ctype="ScrollViewObjectData">
            <Size Y="526" X="550" />
            <AnchorPoint ScaleX="0" ScaleY="0" />
            <Position X="50.780399" Y="201.930893" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData />
            <FirstColor A="255" B="100" G="150" R="255" />
            <EndColor A="255" B="255" G="255" R="255" />
            <ColorVector ScaleX="0" ScaleY="1" />
            <SingleColor A="255" B="100" G="150" R="255" />
            <InnerNodeSize Height="900" Width="640" />
            <Children>
              <AbstractNodeData Name="level_template" ActionTag="1308246608" Tag="269" RotationSkewX="0" RotationSkewY="0" LeftMargin="9.9992" RightMargin="107.000801" TopMargin="126.505203" BottomMargin="622.494812" HorizontalEdge="RightEdge" LeftEage="81" RightEage="81" TopEage="26" BottomEage="26" Scale9OriginX="81" Scale9OriginY="26" Scale9Width="140" Scale9Height="13" Scale9Enable="True" ctype="ImageViewObjectData">
                <Size Y="151" X="523" />
                <AnchorPoint ScaleX="0" ScaleY="1" />
                <Position X="9.9992" Y="773.494812" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/paper_bg1.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="shadow" ActionTag="997890423" Tag="562" RotationSkewX="0" RotationSkewY="0" LeftMargin="75" RightMargin="18" TopMargin="18.001499" BottomMargin="74.998497" HorizontalEdge="LeftEdge" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
                    <Size Y="58" X="430" />
                    <AnchorPoint ScaleX="0" ScaleY="0.5" />
                    <Position X="75" Y="103.998497" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="refresh_btn" ActionTag="-196813884" Tag="408" RotationSkewX="0" RotationSkewY="0" LeftMargin="389.985291" RightMargin="13.0147" TopMargin="46.5616" BottomMargin="41.4384" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="127" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
                    <Size Y="63" X="120" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="449.985291" Y="72.9384" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <NormalFileData Type="PlistSubImage" Path="button/buttonbg_5.png" Plist="ui.plist" />
                    <PressedFileData Type="PlistSubImage" Path="button/buttonbg_5.png" Plist="ui.plist" />
                    <DisabledFileData Type="PlistSubImage" Path="button/buttonbg_5.png" Plist="ui.plist" />
                    <TextColor A="255" B="70" G="65" R="65" />
                    <OutlineColor />
                    <FontResource />
                    <ShadowColor />
                    <Children>
                      <AbstractNodeData Name="desc" ActionTag="229749827" Tag="410" RotationSkewX="0" RotationSkewY="0" LeftMargin="35.0009" RightMargin="36.9991" TopMargin="16.999701" BottomMargin="20.000299" FontSize="24" LabelText="重置" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                        <Size Y="26" X="48" />
                        <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                        <Position X="59.0009" Y="33.000301" />
                        <Scale ScaleX="1" ScaleY="1" />
                        <CColor A="255" B="0" G="0" R="0" />
                        <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                        <OutlineColor />
                        <ShadowColor />
                      </AbstractNodeData>
                    </Children>
                  </AbstractNodeData>
                  <AbstractNodeData Name="icon" ActionTag="907487619" Tag="134" RotationSkewX="0" RotationSkewY="0" LeftMargin="73.559502" RightMargin="449.440491" TopMargin="73.879303" BottomMargin="77.120697" CallBackType="None" CallBackName="None" ctype="ProjectNodeObjectData">
                    <Size Y="0" X="0" />
                    <AnchorPoint ScaleX="0" ScaleY="0" />
                    <Position X="73.559502" Y="77.120697" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="condition" ActionTag="398674019" Tag="270" RotationSkewX="0" RotationSkewY="0" LeftMargin="143.090607" RightMargin="135.909393" TopMargin="92.666199" BottomMargin="31.333799" VerticalEdge="TopEdge" FontSize="20" LabelText="$$$需要当前杂兵等级高于lv1" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="27" X="244" />
                    <AnchorPoint ScaleX="0" ScaleY="1" />
                    <Position X="143.090607" Y="58.333801" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="42" G="73" R="87" />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <OutlineColor />
                    <ShadowColor />
                  </AbstractNodeData>
                  <AbstractNodeData Name="desc" ActionTag="1965134855" Tag="272" RotationSkewX="0" RotationSkewY="0" LeftMargin="140.859497" RightMargin="70.140602" TopMargin="32.521198" BottomMargin="80.478798" VerticalEdge="TopEdge" FontSize="24" LabelText="$$$杂兵等级重置到lv1" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="38" X="312" />
                    <AnchorPoint ScaleX="0" ScaleY="1" />
                    <Position X="140.859497" Y="118.478798" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <OutlineColor />
                    <ShadowColor />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="bottom_shadow" ActionTag="643224225" Tag="267" RotationSkewX="0" RotationSkewY="0" LeftMargin="47.999802" RightMargin="48.000198" TopMargin="887.000122" BottomMargin="202.999893" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="106" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="46" X="544" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="319.999786" Y="225.999893" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/rolling_container_border.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="shadow" ActionTag="-946333376" Tag="268" RotationSkewX="0" RotationSkewY="0" LeftMargin="47.999599" RightMargin="48.000401" TopMargin="406.000397" BottomMargin="683.999573" Alpha="127" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="106" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="46" X="544" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="319.999603" Y="706.999573" />
            <Scale ScaleX="1" ScaleY="-1" />
            <CColor A="255" B="0" G="0" R="0" />
            <FileData Type="PlistSubImage" Path="border/rolling_container_border.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="level_bg" ActionTag="569504828" Tag="158" RotationSkewX="0" RotationSkewY="0" LeftMargin="60.486301" RightMargin="61.513699" TopMargin="324.004486" BottomMargin="741.995483" Alpha="127" LeftEage="30" RightEage="30" TopEage="30" BottomEage="30" Scale9OriginX="30" Scale9OriginY="30" Scale9Width="10" Scale9Height="10" Scale9Enable="True" ctype="ImageViewObjectData">
            <Size Y="70" X="518" />
            <AnchorPoint ScaleX="0" ScaleY="0.5" />
            <Position X="60.486301" Y="776.995483" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/floating_layerbg.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="level_desc" ActionTag="-971970429" Tag="159" RotationSkewX="0" RotationSkewY="0" LeftMargin="143.5" RightMargin="295.5" TopMargin="346.999695" BottomMargin="767.000305" FontSize="20" LabelText="当前魔铁巨像杂兵等级" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
            <Size Y="22" X="201" />
            <AnchorPoint ScaleX="0" ScaleY="0.461" />
            <Position X="143.5" Y="777.143005" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="0" G="204" R="255" />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <OutlineColor />
            <ShadowColor />
          </AbstractNodeData>
          <AbstractNodeData Name="level_icon" ActionTag="-1871313929" Tag="160" RotationSkewX="0" RotationSkewY="0" LeftMargin="79.923401" RightMargin="504.076599" TopMargin="330.691498" BottomMargin="749.308472" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="56" Scale9Height="56" ctype="ImageViewObjectData">
            <Size Y="56" X="56" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="107.923401" Y="777.308472" />
            <Scale ScaleX="0.7" ScaleY="0.7" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="icon/resource/golem.png" Plist="icon.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="level_value" ActionTag="-514049944" Tag="161" RotationSkewX="0" RotationSkewY="0" LeftMargin="503.500214" RightMargin="98.499802" TopMargin="346.999908" BottomMargin="763.000122" FontSize="24" LabelText="Lv24" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
            <Size Y="26" X="38" />
            <AnchorPoint ScaleX="1" ScaleY="0.5" />
            <Position X="541.500183" Y="776.000122" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
            <OutlineColor />
            <ShadowColor />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>
