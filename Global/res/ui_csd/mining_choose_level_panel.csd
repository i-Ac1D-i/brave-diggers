<GameFile>
  <PropertyGroup Name="mining_choose_level_panel" Type="Layer" ID="kmpt01oxrqn8lhc5s2ey964uw3i-vd7jzfag" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.000000">
      </Animation>
      <ObjectData Name="Layer" ctype="GameNodeObjectData">
        <Size X="640.000000" Y="1136.000000" />
        <Children>
          <AbstractNodeData Name="bg" ActionTag="1621371784" Tag="2006" RotationSkewX="0" RotationSkewY="0" LeftMargin="240" RightMargin="240" TopMargin="426" BottomMargin="426" CallBackType="None" CallBackName="None" ctype="SpriteObjectData">
            <Size Y="284" X="160" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="568" />
            <Scale ScaleX="4" ScaleY="4" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/fate_n_transmigration_bg_f.png" Plist="ui.plist" />
            <BlendFunc />
          </AbstractNodeData>
          <AbstractNodeData Name="template" ActionTag="712673349" Tag="214" RotationSkewX="0" RotationSkewY="0" LeftMargin="9.0001" RightMargin="8.9999" TopMargin="423.000092" BottomMargin="602.999878" LeftEage="56" RightEage="56" TopEage="-5" BottomEage="-5" Scale9OriginX="56" Scale9OriginY="-5" Scale9Width="199" Scale9Height="61" ctype="ImageViewObjectData">
            <Size Y="110" X="622" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320.000092" Y="657.999878" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/paper_bg6_d.png" Plist="ui.plist" />
            <Children>
              <AbstractNodeData Name="levelbg" ActionTag="259897568" Tag="223" RotationSkewX="0" RotationSkewY="0" LeftMargin="39" RightMargin="528.999878" TopMargin="23.9998" BottomMargin="32.000198" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                <Size Y="54" X="54" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="66" Y="59.000198" />
                <Scale ScaleX="2" ScaleY="2" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="level" ActionTag="-1099278716" Tag="228" RotationSkewX="0" RotationSkewY="0" LeftMargin="48.9995" RightMargin="537.000488" TopMargin="22.5023" BottomMargin="22.4977" LabelText="1" ctype="TextBMFontObjectData">
                <Size Y="65" X="36" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="66.999496" Y="54.9977" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <LabelBMFontFile_CNB Type="Normal" Path="fonts/number3.fnt" Plist="" />
              </AbstractNodeData>
              <AbstractNodeData Name="bp_icon" ActionTag="-524272114" Tag="1099" RotationSkewX="0" RotationSkewY="0" LeftMargin="145.999298" RightMargin="448.000702" TopMargin="54" BottomMargin="24" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="28" Scale9Height="32" ctype="ImageViewObjectData">
                <Size Y="32" X="28" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="159.999298" Y="40" />
                <Scale ScaleX="0.8" ScaleY="0.8" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/mercenarylist/fighting_capacity.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="levels_desc" ActionTag="-1850830729" Tag="229" RotationSkewX="0" RotationSkewY="0" LeftMargin="145.999695" RightMargin="-285.999786" TopMargin="-57.331001" BottomMargin="59.331001" FontSize="28" LabelText="$$$恶魔洞穴洞穴" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="30" X="204" />
                <AnchorPoint ScaleX="0" ScaleY="0.5" />
                <Position X="145.999695" Y="74.331001" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="42" G="73" R="87" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="condition_desc" Visible="False" ActionTag="-1626437515" Tag="1249" RotationSkewX="0" RotationSkewY="0" LeftMargin="145.999695" RightMargin="308.000214" TopMargin="35.669102" BottomMargin="44.330898" FontSize="28" LabelText="需要通过难度%d的战斗" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="30" X="283" />
                <AnchorPoint ScaleX="0" ScaleY="0.5" />
                <Position X="145.999695" Y="59.330898" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="30" G="28" R="172" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="bp_value" ActionTag="-190593631" Tag="1097" RotationSkewX="0" RotationSkewY="0" LeftMargin="176.999603" RightMargin="-300.999603" TopMargin="-18.330999" BottomMargin="28.330999" FontSize="20" LabelText="$$$需要战力 57567888 / 57385598" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="22" X="287" />
                <AnchorPoint ScaleX="0" ScaleY="0.5" />
                <Position X="176.999603" Y="39.331001" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="75" G="95" R="156" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="challenge_btn" ActionTag="344184260" Tag="937" RotationSkewX="0" RotationSkewY="0" LeftMargin="524.357788" RightMargin="13.6422" TopMargin="12.9998" BottomMargin="23.0002" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="84" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
                <Size Y="74" X="84" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="566.357788" Y="60.000198" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <NormalFileData Type="PlistSubImage" Path="button/buttonbg_9.png" Plist="ui.plist" />
                <PressedFileData Type="PlistSubImage" Path="button/buttonbg_9.png" Plist="ui.plist" />
                <DisabledFileData Type="PlistSubImage" Path="button/buttonbg_9.png" Plist="ui.plist" />
                <TextColor A="255" B="70" G="65" R="65" />
                <OutlineColor />
                <FontResource />
                <ShadowColor />
                <Children>
                  <AbstractNodeData Name="challenge_icon" ActionTag="-24565930" Tag="938" RotationSkewX="0" RotationSkewY="0" LeftMargin="19" RightMargin="-39" TopMargin="-29.0002" BottomMargin="12.0002" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                    <Size Y="52" X="48" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="43" Y="38.000198" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="lock_tip" ActionTag="265891383" Tag="1247" RotationSkewX="0" RotationSkewY="0" LeftMargin="45.325699" RightMargin="530.674316" TopMargin="23.5" BottomMargin="33.5" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                <Size Y="53" X="46" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="68.295601" Y="60" />
                <Scale ScaleX="2" ScaleY="2" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="lock_tip2" ActionTag="534345632" Tag="1248" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1.7689" RightMargin="1.7689" TopMargin="-0.0004" BottomMargin="0.0004" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                    <Size Y="53" X="46" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="21.229" Y="26.500401" />
                    <Scale ScaleX="-1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="list_view" ActionTag="522352980" Tag="82" RotationSkewX="0" RotationSkewY="0" LeftMargin="-0.0003" RightMargin="0.0003" TopMargin="421" BottomMargin="164" TouchEnable="True" BackColorAlpha="102" DirectionType="Vertical" HorizontalType="Align_HorizontalCenter" VerticalType="0" ItemMargin="18" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="0" Scale9Height="0" ctype="ListViewObjectData">
            <Size Y="551" X="640" />
            <AnchorPoint ScaleX="0" ScaleY="0" />
            <Position X="-0.0003" Y="164" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData />
            <FirstColor A="255" B="255" G="150" R="150" />
            <EndColor A="255" B="255" G="255" R="255" />
            <ColorVector ScaleX="0" ScaleY="1" />
            <SingleColor A="255" B="255" G="150" R="150" />
          </AbstractNodeData>
          <AbstractNodeData Name="bottom_bg" ActionTag="-2045122718" Tag="791" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="992.000122" BottomMargin="-81.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
            <Size Y="225" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="1" />
            <Position X="320" Y="143.999893" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="dpwn_border" ActionTag="2069764266" Tag="792" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="902" BottomMargin="120" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="320" Scale9Height="62" ctype="ImageViewObjectData">
            <Size Y="114" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="177" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/herodetail_border_d.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="top_bg" ActionTag="-313030548" Tag="793" RotationSkewX="0" RotationSkewY="0" LeftMargin="159.999893" RightMargin="160.000107" TopMargin="52" BottomMargin="910" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="320" Scale9Height="170" ctype="ImageViewObjectData">
            <Size Y="174" X="320" />
            <AnchorPoint ScaleX="0.5" ScaleY="1" />
            <Position X="319.999908" Y="1084" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="102" G="122" R="141" />
            <FileData Type="PlistSubImage" Path="mining/deep3.png" Plist="mining.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="mission2_2" ActionTag="-1725633506" Tag="133" RotationSkewX="0" RotationSkewY="0" LeftMargin="274" RightMargin="274" TopMargin="287.665009" BottomMargin="822.335022" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="26" X="92" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="835.335022" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="127" G="127" R="127" />
            <FileData Type="PlistSubImage" Path="mining/float_ground.png" Plist="mining.plist" />
            <Children>
              <AbstractNodeData Name="floatstone_top" ActionTag="-1336604935" Tag="134" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="-78.000198" BottomMargin="21.0002" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="83" ctype="ImageViewObjectData">
                <Size Y="83" X="92" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46" Y="62.500198" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/city_dibiao_z.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="shadow" ActionTag="2045088086" Tag="135" RotationSkewX="0" RotationSkewY="0" LeftMargin="22.996799" RightMargin="22.003201" TopMargin="-28.75" BottomMargin="41.75" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="29" Scale9Height="12" ctype="ImageViewObjectData">
                <Size Y="13" X="47" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46.496799" Y="48.25" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/maze_role_shadow_d.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="spec_roundbg" ActionTag="979427693" Tag="286" RotationSkewX="0" RotationSkewY="0" LeftMargin="20" RightMargin="18" TopMargin="-72" BottomMargin="44" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                <Size Y="54" X="54" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="icon" ActionTag="-1656187699" Tag="137" RotationSkewX="0" RotationSkewY="0" LeftMargin="19" RightMargin="17" TopMargin="-73.25" BottomMargin="43.25" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="56" Scale9Height="56" ctype="ImageViewObjectData">
                <Size Y="56" X="56" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71.25" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/resource/emerald.png" Plist="icon.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="lock_tip" ActionTag="-1670585070" Tag="138" RotationSkewX="0" RotationSkewY="0" LeftMargin="24.999901" RightMargin="21.000099" TopMargin="-68.499901" BottomMargin="41.499901" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                <Size Y="53" X="46" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47.996399" Y="67.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="lock_tip2" ActionTag="-279085011" Tag="139" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1.7689" RightMargin="1.7689" TopMargin="-0.0004" BottomMargin="0.0004" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                    <Size Y="53" X="46" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="21.229" Y="26.500401" />
                    <Scale ScaleX="-1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="decorate" ActionTag="1347965074" Tag="140" RotationSkewX="0" RotationSkewY="0" LeftMargin="55.500401" RightMargin="9.4996" TopMargin="-22.999901" BottomMargin="28.999901" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="27" Scale9Height="20" ctype="ImageViewObjectData">
                <Size Y="20" X="27" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="69.000397" Y="38.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/city_decorate7.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="times" ActionTag="-958551209" Tag="141" RotationSkewX="0" RotationSkewY="0" LeftMargin="-4.5001" RightMargin="48.500099" TopMargin="-51.000099" BottomMargin="25.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                <Size Y="52" X="48" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="19.499901" Y="51.000099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="shadow" ActionTag="-553244953" Tag="142" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1" RightMargin="-1" TopMargin="18.999901" BottomMargin="-16.999901" Alpha="204" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="50" Scale9Height="50" ctype="ImageViewObjectData">
                    <Size Y="50" X="50" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24" Y="8.0001" />
                    <Scale ScaleX="0.7" ScaleY="0.7" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/battle_fightnumber_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="value" ActionTag="-705625723" Tag="143" RotationSkewX="0" RotationSkewY="0" LeftMargin="15.1201" RightMargin="14.8799" TopMargin="33.25" BottomMargin="-3.25" FontSize="20" LabelText="10" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="22" X="18" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24.1201" Y="7.75" />
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
          <AbstractNodeData Name="mission2_1" ActionTag="-667996175" Tag="122" RotationSkewX="0" RotationSkewY="0" LeftMargin="70.171303" RightMargin="477.828705" TopMargin="287.665192" BottomMargin="822.334778" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="26" X="92" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="116.171303" Y="835.334778" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="mining/float_ground.png" Plist="mining.plist" />
            <Children>
              <AbstractNodeData Name="floatstone_top" ActionTag="-19180668" Tag="123" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="-78.000397" BottomMargin="21.000401" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="83" ctype="ImageViewObjectData">
                <Size Y="83" X="92" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46" Y="62.500401" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/city_dibiao_z.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="shadow" ActionTag="-959357914" Tag="124" RotationSkewX="0" RotationSkewY="0" LeftMargin="22.999901" RightMargin="22.000099" TopMargin="-28.75" BottomMargin="41.75" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="29" Scale9Height="12" ctype="ImageViewObjectData">
                <Size Y="13" X="47" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46.496799" Y="48.25" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/maze_role_shadow_d.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="spec_roundbg" ActionTag="-1087915924" Tag="285" RotationSkewX="0" RotationSkewY="0" LeftMargin="20" RightMargin="18" TopMargin="-72" BottomMargin="44" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                <Size Y="54" X="54" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="icon" ActionTag="521308491" Tag="126" RotationSkewX="0" RotationSkewY="0" LeftMargin="19" RightMargin="17" TopMargin="-72.750099" BottomMargin="42.750099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="56" Scale9Height="56" ctype="ImageViewObjectData">
                <Size Y="56" X="56" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="70.750099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/resource/iron.png" Plist="icon.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="lock_tip" ActionTag="559817950" Tag="127" RotationSkewX="0" RotationSkewY="0" LeftMargin="25" RightMargin="21" TopMargin="-68.499901" BottomMargin="41.499901" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                <Size Y="53" X="46" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47.996399" Y="67.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="lock_tip2" ActionTag="1720737440" Tag="128" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1.7689" RightMargin="1.7689" TopMargin="-0.0004" BottomMargin="0.0004" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                    <Size Y="53" X="46" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="21.229" Y="26.500401" />
                    <Scale ScaleX="-1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="times" ActionTag="-775630607" Tag="129" RotationSkewX="0" RotationSkewY="0" LeftMargin="-4.5001" RightMargin="48.500099" TopMargin="-51.000099" BottomMargin="25.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                <Size Y="52" X="48" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="19.499901" Y="51.000099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="shadow" ActionTag="397467840" Tag="130" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1" RightMargin="-1" TopMargin="18.999901" BottomMargin="-16.999901" Alpha="204" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="50" Scale9Height="50" ctype="ImageViewObjectData">
                    <Size Y="50" X="50" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24" Y="8.0001" />
                    <Scale ScaleX="0.7" ScaleY="0.7" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/battle_fightnumber_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="value" ActionTag="1171956843" Tag="131" RotationSkewX="0" RotationSkewY="0" LeftMargin="15.1201" RightMargin="14.8799" TopMargin="33.25" BottomMargin="-3.25" FontSize="20" LabelText="10" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="22" X="18" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24.1201" Y="7.75" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <OutlineColor />
                    <ShadowColor />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="decorate" ActionTag="-913870424" Tag="132" RotationSkewX="0" RotationSkewY="0" LeftMargin="62.000401" RightMargin="10.9996" TopMargin="-28.999701" BottomMargin="29.999701" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="19" Scale9Height="25" ctype="ImageViewObjectData">
                <Size Y="25" X="19" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="71.500397" Y="42.499699" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/city_decorate3.png" Plist="mining.plist" />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="mission2_3" ActionTag="1371443582" Tag="362" RotationSkewX="0" RotationSkewY="0" LeftMargin="478.171814" RightMargin="69.828201" TopMargin="287.665192" BottomMargin="822.334778" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="26" X="92" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="524.171814" Y="835.334778" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="mining/float_ground.png" Plist="mining.plist" />
            <Children>
              <AbstractNodeData Name="floatstone_top" ActionTag="-536452469" Tag="363" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="-78.000397" BottomMargin="21.000401" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="83" ctype="ImageViewObjectData">
                <Size Y="83" X="92" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46" Y="62.500401" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/city_dibiao_z.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="shadow" ActionTag="-967715588" Tag="364" RotationSkewX="0" RotationSkewY="0" LeftMargin="22.999901" RightMargin="22.000099" TopMargin="-28.75" BottomMargin="41.75" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="29" Scale9Height="12" ctype="ImageViewObjectData">
                <Size Y="13" X="47" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46.496799" Y="48.25" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/maze_role_shadow_d.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="spec_roundbg" ActionTag="811051616" Tag="287" RotationSkewX="0" RotationSkewY="0" LeftMargin="20" RightMargin="18" TopMargin="-72" BottomMargin="44" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                <Size Y="54" X="54" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="icon" ActionTag="136815069" Tag="366" RotationSkewX="0" RotationSkewY="0" LeftMargin="19" RightMargin="17" TopMargin="-72.750099" BottomMargin="42.750099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="56" Scale9Height="56" ctype="ImageViewObjectData">
                <Size Y="56" X="56" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="70.750099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/resource/golem.png" Plist="icon.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="lock_tip" ActionTag="1126953122" Tag="367" RotationSkewX="0" RotationSkewY="0" LeftMargin="25" RightMargin="21" TopMargin="-68.499901" BottomMargin="41.499901" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                <Size Y="53" X="46" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47.996399" Y="67.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="lock_tip2" ActionTag="-28253545" Tag="368" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1.7689" RightMargin="1.7689" TopMargin="-0.0004" BottomMargin="0.0004" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                    <Size Y="53" X="46" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="21.229" Y="26.500401" />
                    <Scale ScaleX="-1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="times" ActionTag="196684644" Tag="369" RotationSkewX="0" RotationSkewY="0" LeftMargin="-4.5001" RightMargin="48.500099" TopMargin="-51.000099" BottomMargin="25.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                <Size Y="52" X="48" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="19.499901" Y="51.000099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="shadow" ActionTag="578868036" Tag="370" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1" RightMargin="-1" TopMargin="18.999901" BottomMargin="-16.999901" Alpha="204" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="50" Scale9Height="50" ctype="ImageViewObjectData">
                    <Size Y="50" X="50" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24" Y="8.0001" />
                    <Scale ScaleX="0.7" ScaleY="0.7" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/battle_fightnumber_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="value" ActionTag="1887485068" Tag="371" RotationSkewX="0" RotationSkewY="0" LeftMargin="15.1201" RightMargin="14.8799" TopMargin="33.25" BottomMargin="-3.25" FontSize="20" LabelText="10" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="22" X="18" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24.1201" Y="7.75" />
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
          <AbstractNodeData Name="mission1_1" ActionTag="-259093204" Tag="340" RotationSkewX="0" RotationSkewY="0" LeftMargin="173.000504" RightMargin="374.999512" TopMargin="287.665009" BottomMargin="822.335022" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="26" X="92" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="219.000504" Y="835.335022" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="127" G="127" R="127" />
            <FileData Type="PlistSubImage" Path="mining/float_ground.png" Plist="mining.plist" />
            <Children>
              <AbstractNodeData Name="floatstone_top" ActionTag="-1012704345" Tag="341" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="-81.500198" BottomMargin="24.5002" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="83" ctype="ImageViewObjectData">
                <Size Y="83" X="92" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46" Y="66.000198" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/mud_ground.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="shadow" ActionTag="380643095" Tag="342" RotationSkewX="0" RotationSkewY="0" LeftMargin="22.996799" RightMargin="22.003201" TopMargin="-27.75" BottomMargin="40.75" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="29" Scale9Height="12" ctype="ImageViewObjectData">
                <Size Y="13" X="47" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46.496799" Y="47.25" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/maze_role_shadow_d.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="spec_roundbg" ActionTag="1106845113" Tag="288" RotationSkewX="0" RotationSkewY="0" LeftMargin="20" RightMargin="18" TopMargin="-72.000099" BottomMargin="44.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                <Size Y="54" X="54" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71.000099" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="icon" ActionTag="-169005212" Tag="344" RotationSkewX="0" RotationSkewY="0" LeftMargin="20" RightMargin="17" TopMargin="-73.25" BottomMargin="43.25" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="55" Scale9Height="56" ctype="ImageViewObjectData">
                <Size Y="56" X="55" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47.5" Y="71.25" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/resource/coin_res.png" Plist="icon.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="lock_tip" ActionTag="-526749740" Tag="345" RotationSkewX="0" RotationSkewY="0" LeftMargin="24.999901" RightMargin="21.000099" TopMargin="-68.499901" BottomMargin="41.499901" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                <Size Y="53" X="46" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47.996399" Y="67.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="lock_tip2" ActionTag="465990111" Tag="346" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1.7689" RightMargin="1.7689" TopMargin="-0.0004" BottomMargin="0.0004" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                    <Size Y="53" X="46" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="21.229" Y="26.500401" />
                    <Scale ScaleX="-1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="decorate" ActionTag="-1947186766" Tag="347" RotationSkewX="0" RotationSkewY="0" LeftMargin="57.000401" RightMargin="10.9996" TopMargin="-34.999901" BottomMargin="32.999901" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="24" Scale9Height="28" ctype="ImageViewObjectData">
                <Size Y="28" X="24" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="69.000397" Y="46.999901" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/city_decorate6.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="times" ActionTag="1219193432" Tag="348" RotationSkewX="0" RotationSkewY="0" LeftMargin="-4.5001" RightMargin="48.500099" TopMargin="-51.000099" BottomMargin="25.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                <Size Y="52" X="48" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="19.499901" Y="51.000099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="shadow" ActionTag="-425040760" Tag="349" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1" RightMargin="-1" TopMargin="18.999901" BottomMargin="-16.999901" Alpha="204" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="50" Scale9Height="50" ctype="ImageViewObjectData">
                    <Size Y="50" X="50" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24" Y="8.0001" />
                    <Scale ScaleX="0.7" ScaleY="0.7" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/battle_fightnumber_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="value" ActionTag="1957068198" Tag="350" RotationSkewX="0" RotationSkewY="0" LeftMargin="15.1201" RightMargin="14.8799" TopMargin="33.25" BottomMargin="-3.25" FontSize="20" LabelText="10" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="22" X="18" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24.1201" Y="7.75" />
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
          <AbstractNodeData Name="mission1_2" ActionTag="1316533432" Tag="351" RotationSkewX="0" RotationSkewY="0" LeftMargin="376.000397" RightMargin="171.999603" TopMargin="287.665009" BottomMargin="822.335022" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="26" ctype="ImageViewObjectData">
            <Size Y="26" X="92" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="422.000397" Y="835.335022" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="mining/float_ground.png" Plist="mining.plist" />
            <Children>
              <AbstractNodeData Name="floatstone_top" ActionTag="2135373540" Tag="352" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="-81.500298" BottomMargin="24.500299" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="92" Scale9Height="83" ctype="ImageViewObjectData">
                <Size Y="83" X="92" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46" Y="66.000298" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/mud_ground.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="shadow" ActionTag="-763261096" Tag="353" RotationSkewX="0" RotationSkewY="0" LeftMargin="22.996799" RightMargin="22.003201" TopMargin="-27.75" BottomMargin="40.75" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="29" Scale9Height="12" ctype="ImageViewObjectData">
                <Size Y="13" X="47" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="46.496799" Y="47.25" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/maze_role_shadow_d.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="spec_roundbg" ActionTag="1109516129" Tag="289" RotationSkewX="0" RotationSkewY="0" LeftMargin="20" RightMargin="18" TopMargin="-72.000099" BottomMargin="44.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                <Size Y="54" X="54" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71.000099" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="icon" ActionTag="1237461046" Tag="355" RotationSkewX="0" RotationSkewY="0" LeftMargin="19" RightMargin="17" TopMargin="-73.250099" BottomMargin="43.250099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="56" Scale9Height="56" ctype="ImageViewObjectData">
                <Size Y="56" X="56" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47" Y="71.250099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/resource/exp_resource.png" Plist="icon.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="lock_tip" ActionTag="1887745601" Tag="356" RotationSkewX="0" RotationSkewY="0" LeftMargin="24.999901" RightMargin="21.000099" TopMargin="-68.5" BottomMargin="41.5" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                <Size Y="53" X="46" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="47.996399" Y="68" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="lock_tip2" ActionTag="-522517824" Tag="357" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1.7689" RightMargin="1.7689" TopMargin="-0.0004" BottomMargin="0.0004" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="53" ctype="ImageViewObjectData">
                    <Size Y="53" X="46" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="21.229" Y="26.500401" />
                    <Scale ScaleX="-1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="border/chain.png" Plist="ui.plist" />
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
              <AbstractNodeData Name="decorate" ActionTag="836580122" Tag="358" RotationSkewX="0" RotationSkewY="0" LeftMargin="51.0005" RightMargin="8.9995" TopMargin="-30" BottomMargin="31" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="32" Scale9Height="25" ctype="ImageViewObjectData">
                <Size Y="25" X="32" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="67.000504" Y="43.5" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="mining/mud_decorate1.png" Plist="mining.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="times" ActionTag="-1257298567" Tag="359" RotationSkewX="0" RotationSkewY="0" LeftMargin="-4.5" RightMargin="48.5" TopMargin="-51.000099" BottomMargin="25.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                <Size Y="52" X="48" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="19.5" Y="51.000099" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="shadow" ActionTag="1498690240" Tag="360" RotationSkewX="0" RotationSkewY="0" LeftMargin="-1" RightMargin="-1" TopMargin="18.999901" BottomMargin="-16.999901" Alpha="204" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="50" Scale9Height="50" ctype="ImageViewObjectData">
                    <Size Y="50" X="50" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24" Y="8.0001" />
                    <Scale ScaleX="0.7" ScaleY="0.7" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/battle_fightnumber_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="value" ActionTag="705107957" Tag="361" RotationSkewX="0" RotationSkewY="0" LeftMargin="15.1201" RightMargin="14.8799" TopMargin="33.25" BottomMargin="-3.25" FontSize="20" LabelText="10" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="22" X="18" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="24.1201" Y="7.75" />
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
          <AbstractNodeData Name="title_bg" ActionTag="-1452177526" Tag="1601" RotationSkewX="0" RotationSkewY="0" LeftMargin="129.828796" RightMargin="128.171204" TopMargin="39.664902" BottomMargin="1039.335083" LeftEage="81" RightEage="81" TopEage="0" BottomEage="0" Scale9OriginX="81" Scale9OriginY="0" Scale9Width="29" Scale9Height="57" Scale9Enable="True" ctype="ImageViewObjectData">
            <Size Y="57" X="382" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320.828796" Y="1067.835083" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/maintitle_bg.png" Plist="ui.plist" />
            <Children>
              <AbstractNodeData Name="title" ActionTag="908626550" Tag="1602" RotationSkewX="0" RotationSkewY="0" LeftMargin="78.000397" RightMargin="79.999603" TopMargin="19.4998" BottomMargin="2.5002" FontSize="32" LabelText="$$$以太入侵（关卡名）" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="35" X="330" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="190.000397" Y="20.0002" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="top_border" ActionTag="-1169818664" Tag="794" RotationSkewX="0" RotationSkewY="0" LeftMargin="-0.001" RightMargin="0.001" TopMargin="361.999512" BottomMargin="660.000488" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="320" Scale9Height="62" ctype="ImageViewObjectData">
            <Size Y="114" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="319.998993" Y="717.000488" />
            <Scale ScaleX="1" ScaleY="-1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/herodetail_border_d.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="mission_desc" ActionTag="536136988" Tag="954" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="0" BottomMargin="0" CallBackType="None" CallBackName="None" ctype="SingleNodeObjectData">
            <Size Y="0" X="0" />
            <AnchorPoint ScaleX="0" ScaleY="0" />
            <Position X="0" Y="0" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <Children>
              <AbstractNodeData Name="bg" ActionTag="-345989916" Tag="821" RotationSkewX="0" RotationSkewY="0" LeftMargin="8.9998" RightMargin="9.0001" TopMargin="276.999908" BottomMargin="741.000122" LeftEage="56" RightEage="56" TopEage="-5" BottomEage="-5" Scale9OriginX="56" Scale9OriginY="-5" Scale9Width="199" Scale9Height="61" ctype="ImageViewObjectData">
                <Size Y="118" X="622" />
                <AnchorPoint ScaleX="0.5" ScaleY="0" />
                <Position X="319.999786" Y="741.000122" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="137" G="255" R="226" />
                <FileData Type="PlistSubImage" Path="bg/paper_bg6_d.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="decorate" ActionTag="393967952" Tag="872" RotationSkewX="0" RotationSkewY="0" LeftMargin="32.000301" RightMargin="-40.000301" TopMargin="-787.001526" BottomMargin="771.001526" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="8" Scale9Height="16" ctype="ImageViewObjectData">
                <Size Y="16" X="8" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="36.000301" Y="779.001526" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="button/detailbtn_icon.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="desc" ActionTag="1398264241" Tag="831" RotationSkewX="0" RotationSkewY="0" LeftMargin="50.998699" RightMargin="-270.998688" TopMargin="-789.331116" BottomMargin="767.331116" FontSize="20" LabelText="$$$掉落低级，中级矿石资源" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="22" X="247" />
                <AnchorPoint ScaleX="0" ScaleY="0.5" />
                <Position X="50.998699" Y="778.331116" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="42" G="87" R="74" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="arrow" ActionTag="1988522526" Tag="876" RotationSkewX="0" RotationSkewY="0" LeftMargin="391.5" RightMargin="-452.5" TopMargin="-884.500427" BottomMargin="837.500427" CallBackType="None" CallBackName="None" ctype="SpriteObjectData">
                <Size Y="47" X="61" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="422" Y="861.000427" />
                <Scale ScaleX="1" ScaleY="-1" />
                <CColor A="255" B="137" G="255" R="226" />
                <FileData Type="PlistSubImage" Path="border/dialoge_arrow.png" Plist="ui.plist" />
                <BlendFunc />
              </AbstractNodeData>
              <AbstractNodeData Name="shadow" ActionTag="-1598742871" Tag="870" RotationSkewX="0" RotationSkewY="0" LeftMargin="23.9998" RightMargin="-617.999817" TopMargin="-842.001404" BottomMargin="800.001404" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
                <Size Y="42" X="594" />
                <AnchorPoint ScaleX="0" ScaleY="1" />
                <Position X="23.9998" Y="842.001404" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="165" G="255" R="226" />
                <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="name" ActionTag="-2089602090" Tag="871" RotationSkewX="0" RotationSkewY="0" LeftMargin="47" RightMargin="-335.999908" TopMargin="-834.002014" BottomMargin="796.002014" FontSize="24" LabelText="$$$以太入侵南部据点" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="38" X="289" />
                <AnchorPoint ScaleX="0" ScaleY="1" />
                <Position X="47" Y="834.002014" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="time" ActionTag="-759011943" Tag="873" RotationSkewX="0" RotationSkewY="0" LeftMargin="316.999908" RightMargin="-605.999878" TopMargin="-834.002014" BottomMargin="796.002014" FontSize="24" LabelText="$$$逢周一/周三/周四开启" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="38" X="289" />
                <AnchorPoint ScaleX="1" ScaleY="1" />
                <Position X="605.999878" Y="834.002014" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="124" G="185" R="176" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="bottom_bar" ActionTag="-1225809554" Tag="986" RotationSkewX="0" RotationSkewY="0" LeftMargin="0.0019" RightMargin="-0.0019" TopMargin="845.000488" BottomMargin="166.999496" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="320" Scale9Height="62" ctype="ImageViewObjectData">
            <Size Y="124" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320.001892" Y="228.999496" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/herodetail_border_d.png" Plist="ui.plist" />
            <Children>
              <AbstractNodeData Name="bg1" ActionTag="1780495726" Tag="987" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="108" BottomMargin="-69" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
                <Size Y="85" X="640" />
                <AnchorPoint ScaleX="0.5" ScaleY="1" />
                <Position X="320" Y="16" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="bg2" ActionTag="-559084406" Tag="988" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="88.5" BottomMargin="-25.5" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
                <Size Y="61" X="640" />
                <AnchorPoint ScaleX="0.5" ScaleY="1" />
                <Position X="320" Y="35.5" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/bottom_bg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="badge_bg" ActionTag="-151017111" Tag="786" RotationSkewX="0" RotationSkewY="0" LeftMargin="391.002197" RightMargin="-1.0022" TopMargin="82.755402" BottomMargin="-28.7554" TouchEnable="True" Alpha="178" LeftEage="20" RightEage="20" TopEage="20" BottomEage="20" Scale9OriginX="20" Scale9OriginY="20" Scale9Width="30" Scale9Height="30" Scale9Enable="True" ctype="ImageViewObjectData">
                <Size Y="70" X="250" />
                <AnchorPoint ScaleX="1" ScaleY="0.5" />
                <Position X="641.002197" Y="6.2446" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/floating_layerbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="demon_badge_icon" ActionTag="-93219158" Tag="787" RotationSkewX="0" RotationSkewY="0" LeftMargin="402.339203" RightMargin="181.660797" TopMargin="89.668404" BottomMargin="-21.6684" ZOrder="1" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="56" Scale9Height="56" ctype="ImageViewObjectData">
                <Size Y="56" X="56" />
                <AnchorPoint ScaleX="0.508" ScaleY="0.504" />
                <Position X="430.787201" Y="6.5556" />
                <Scale ScaleX="0.75" ScaleY="0.75" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/resource/demon_medal.png" Plist="icon.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="badge_number" ActionTag="-1428963160" Tag="788" RotationSkewX="0" RotationSkewY="0" LeftMargin="596.995789" RightMargin="22.0042" TopMargin="105.002197" BottomMargin="-7.0022" FontSize="24" LabelText="22" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="26" X="21" />
                <AnchorPoint ScaleX="1" ScaleY="0.5" />
                <Position X="617.995789" Y="5.9978" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="badge_desc" ActionTag="2125592757" Tag="789" RotationSkewX="0" RotationSkewY="0" LeftMargin="458.002014" RightMargin="69.998001" TopMargin="103.001701" BottomMargin="-9.0017" FontSize="28" LabelText="恶魔徽章" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="30" X="112" />
                <AnchorPoint ScaleX="0" ScaleY="0.5" />
                <Position X="458.002014" Y="5.9983" />
                <Scale ScaleX="0.7" ScaleY="0.7" />
                <CColor A="255" B="148" G="228" R="251" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="times_bg" ActionTag="363084766" Tag="1092" RotationSkewX="0" RotationSkewY="0" LeftMargin="150.002197" RightMargin="239.997803" TopMargin="82.755402" BottomMargin="-28.7554" TouchEnable="True" Alpha="178" LeftEage="20" RightEage="20" TopEage="20" BottomEage="20" Scale9OriginX="20" Scale9OriginY="20" Scale9Width="30" Scale9Height="30" Scale9Enable="True" ctype="ImageViewObjectData">
                <Size Y="70" X="250" />
                <AnchorPoint ScaleX="1" ScaleY="0.5" />
                <Position X="400.002197" Y="6.2446" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/floating_layerbg.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="times_icon" ActionTag="1444789801" Tag="1093" RotationSkewX="0" RotationSkewY="0" LeftMargin="162.402603" RightMargin="429.597412" TopMargin="91.652496" BottomMargin="-19.6525" ZOrder="1" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="48" Scale9Height="52" ctype="ImageViewObjectData">
                <Size Y="52" X="48" />
                <AnchorPoint ScaleX="0.508" ScaleY="0.504" />
                <Position X="186.786606" Y="6.5555" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="icon/global/fight_globalicon.png" Plist="ui.plist" />
              </AbstractNodeData>
              <AbstractNodeData Name="times_number" ActionTag="1375314933" Tag="1094" RotationSkewX="0" RotationSkewY="0" LeftMargin="323.995605" RightMargin="295.004395" TopMargin="105.002098" BottomMargin="-7.0021" FontSize="24" LabelText="22" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="26" X="21" />
                <AnchorPoint ScaleX="1" ScaleY="0.5" />
                <Position X="344.995605" Y="5.9979" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="times_desc" ActionTag="27297107" Tag="1095" RotationSkewX="0" RotationSkewY="0" LeftMargin="211.001602" RightMargin="288.998413" TopMargin="103.002098" BottomMargin="-9.0021" FontSize="28" LabelText="本据点次数" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="30" X="140" />
                <AnchorPoint ScaleX="0" ScaleY="0.5" />
                <Position X="211.001602" Y="5.9979" />
                <Scale ScaleX="0.7" ScaleY="0.7" />
                <CColor A="255" B="148" G="228" R="251" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
              <AbstractNodeData Name="times_buy_btn" ActionTag="1754728954" Tag="1096" RotationSkewX="0" RotationSkewY="0" LeftMargin="351.999512" RightMargin="256.000488" TopMargin="102.000099" BottomMargin="-10.0001" TouchEnable="True" Scale9Enable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="32" Scale9Height="32" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
                <Size Y="32" X="32" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="367.999512" Y="5.9999" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <NormalFileData Type="PlistSubImage" Path="button/buy_blood.png" Plist="ui.plist" />
                <PressedFileData Type="PlistSubImage" Path="button/buy_blood.png" Plist="ui.plist" />
                <DisabledFileData Type="PlistSubImage" Path="button/buy_blood.png" Plist="ui.plist" />
                <TextColor A="255" B="70" G="65" R="65" />
                <OutlineColor />
                <FontResource />
                <ShadowColor />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="back_btn" ActionTag="-886023877" Tag="2002" RotationSkewX="0" RotationSkewY="0" LeftMargin="-81.5" RightMargin="488.5" TopMargin="926.000305" BottomMargin="135.999695" TouchEnable="True" Scale9Enable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="233" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
            <Size Y="74" X="233" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="35" Y="172.999695" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <NormalFileData Type="PlistSubImage" Path="button/buttonbg_1.png" Plist="ui.plist" />
            <PressedFileData Type="PlistSubImage" Path="button/buttonbg_1.png" Plist="ui.plist" />
            <DisabledFileData Type="PlistSubImage" Path="button/buttonbg_1.png" Plist="ui.plist" />
            <TextColor A="255" B="70" G="65" R="65" />
            <OutlineColor />
            <FontResource />
            <ShadowColor />
            <Children>
              <AbstractNodeData Name="icon" ActionTag="293494642" Tag="2003" RotationSkewX="0" RotationSkewY="0" LeftMargin="103.499603" RightMargin="36.500401" TopMargin="25" BottomMargin="25" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="93" Scale9Height="24" ctype="ImageViewObjectData">
                <Size Y="24" X="93" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="149.999603" Y="37" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="button/backbtn_icon.png" Plist="ui.plist" />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>
