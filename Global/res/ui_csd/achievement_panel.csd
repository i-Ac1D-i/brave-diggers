<GameFile>
  <PropertyGroup Name="achievement_panel" Type="Layer" ID="noyrspkjbafzw3g5hxlei8-q0ctm49v26u17" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.000000">
      </Animation>
      <ObjectData Name="Layer" ctype="GameNodeObjectData">
        <Size X="640.000000" Y="1136.000000" />
        <Children>
          <AbstractNodeData Name="bg" ActionTag="-76100608" Tag="160" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="0" BottomMargin="0" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="160" Scale9Height="284" ctype="ImageViewObjectData">
            <Size Y="1136" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="568" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/temple_bg_f.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="scroll_view" ActionTag="1779670674" Tag="161" RotationSkewX="0" RotationSkewY="0" LeftMargin="-0.0016" RightMargin="0.0016" TopMargin="106.000603" BottomMargin="159.999405" TouchEnable="True" BackColorAlpha="102" ScrollDirectionType="Horizontal" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="1" Scale9Height="1" ClipAble="True" ctype="ScrollViewObjectData">
            <Size Y="870" X="640" />
            <AnchorPoint ScaleX="0" ScaleY="0" />
            <Position X="-0.0016" Y="159.999405" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData />
            <FirstColor A="255" B="100" G="150" R="255" />
            <EndColor A="255" B="255" G="255" R="255" />
            <ColorVector ScaleX="0" ScaleY="1" />
            <SingleColor A="255" B="100" G="150" R="255" />
            <InnerNodeSize Height="880" Width="640" />
            <Children>
              <AbstractNodeData Name="template" ActionTag="-1411279210" Tag="162" RotationSkewX="0" RotationSkewY="0" LeftMargin="8" RightMargin="10" TopMargin="534.5" BottomMargin="189.5" LeftEage="81" RightEage="81" TopEage="26" BottomEage="26" Scale9OriginX="81" Scale9OriginY="26" Scale9Width="140" Scale9Height="13" Scale9Enable="True" ctype="ImageViewObjectData">
                <Size Y="156" X="622" />
                <AnchorPoint ScaleX="0.5" ScaleY="0" />
                <Position X="319" Y="189.5" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="bg/paper_bg1.png" Plist="ui.plist" />
                <Children>
                  <AbstractNodeData Name="arrow" ActionTag="-1671723467" Tag="193" RotationSkewX="0" RotationSkewY="0" LeftMargin="148" RightMargin="466" TopMargin="100.999901" BottomMargin="39.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="8" Scale9Height="16" ctype="ImageViewObjectData">
                    <Size Y="16" X="8" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="152" Y="47.000099" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="button/detailbtn_icon.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="loading_desc" ActionTag="313914605" Tag="194" RotationSkewX="0" RotationSkewY="0" LeftMargin="162.119202" RightMargin="339.880798" TopMargin="98.6661" BottomMargin="35.3339" FontSize="20" LabelText="当前成就进度" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="22" X="120" />
                    <AnchorPoint ScaleX="0" ScaleY="0.5" />
                    <Position X="162.119202" Y="46.3339" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="16" G="83" R="74" />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <OutlineColor />
                    <ShadowColor />
                  </AbstractNodeData>
                  <AbstractNodeData Name="shadow" ActionTag="1386929349" Tag="190" RotationSkewX="0" RotationSkewY="0" LeftMargin="97.999901" RightMargin="19.000099" TopMargin="18.999701" BottomMargin="77.000298" Alpha="38" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
                    <Size Y="60" X="505" />
                    <AnchorPoint ScaleX="0" ScaleY="0.5" />
                    <Position X="97.999901" Y="107.000298" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="desc" ActionTag="2088141384" Tag="163" RotationSkewX="0" RotationSkewY="0" LeftMargin="144.999802" RightMargin="89.000099" TopMargin="36.000099" BottomMargin="62.999901" FontSize="24" LabelText="$$$在竞技场获得过1胜奖励超过360次" IsCustomSize="True" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="57" X="388" />
                    <AnchorPoint ScaleX="0" ScaleY="1" />
                    <Position X="144.999802" Y="119.999901" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="17" G="17" R="17" />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <OutlineColor />
                    <ShadowColor />
                  </AbstractNodeData>
                  <AbstractNodeData Name="star6" ActionTag="-1587472203" Tag="164" RotationSkewX="0" RotationSkewY="0" LeftMargin="453.999512" RightMargin="148.000504" TopMargin="100.000397" BottomMargin="35.999599" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                    <Size Y="20" X="20" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="463.999512" Y="45.999599" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="star5" ActionTag="1071754503" Tag="165" RotationSkewX="0" RotationSkewY="0" LeftMargin="478.713409" RightMargin="123.286598" TopMargin="100.286201" BottomMargin="35.713799" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                    <Size Y="20" X="20" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="488.713409" Y="45.713799" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="star4" ActionTag="-1602468372" Tag="166" RotationSkewX="0" RotationSkewY="0" LeftMargin="503.714294" RightMargin="98.285698" TopMargin="100.285896" BottomMargin="35.7141" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                    <Size Y="20" X="20" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="513.714294" Y="45.7141" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="star3" ActionTag="1837444608" Tag="167" RotationSkewX="0" RotationSkewY="0" LeftMargin="528.713623" RightMargin="73.2864" TopMargin="100.285896" BottomMargin="35.7141" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                    <Size Y="20" X="20" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="538.713623" Y="45.7141" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="star2" ActionTag="733314012" Tag="191" RotationSkewX="0" RotationSkewY="0" LeftMargin="553.713379" RightMargin="48.286598" TopMargin="100.285896" BottomMargin="35.7141" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                    <Size Y="20" X="20" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="563.713379" Y="45.7141" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="star1" ActionTag="877072174" Tag="192" RotationSkewX="0" RotationSkewY="0" LeftMargin="579.000427" RightMargin="22.999599" TopMargin="99.999901" BottomMargin="36.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                    <Size Y="20" X="20" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="589.000427" Y="46.000099" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="value" ActionTag="870224881" Tag="168" RotationSkewX="0" RotationSkewY="0" LeftMargin="291.999512" RightMargin="193.000504" TopMargin="94.999901" BottomMargin="35.000099" FontSize="24" LabelText="200.34k/200.34k" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                    <Size Y="26" X="137" />
                    <AnchorPoint ScaleX="0" ScaleY="0.5" />
                    <Position X="291.999512" Y="48.000099" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="56" G="78" R="109" />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <OutlineColor />
                    <ShadowColor />
                  </AbstractNodeData>
                  <AbstractNodeData Name="get_btn" ActionTag="-967924711" Tag="169" RotationSkewX="0" RotationSkewY="0" LeftMargin="507.500214" RightMargin="15.4998" TopMargin="13.9995" BottomMargin="72.000504" TouchEnable="True" Scale9Enable="True" LeftEage="27" RightEage="27" TopEage="22" BottomEage="22" Scale9OriginX="27" Scale9OriginY="22" Scale9Width="73" Scale9Height="30" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="领取" FontSize="24" ctype="ButtonObjectData">
                    <Size Y="70" X="99" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="557.000183" Y="107.000504" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <NormalFileData Type="PlistSubImage" Path="button/buttonbg_5.png" Plist="ui.plist" />
                    <PressedFileData Type="PlistSubImage" Path="button/buttonbg_5.png" Plist="ui.plist" />
                    <DisabledFileData Type="PlistSubImage" Path="button/buttonbg_5.png" Plist="ui.plist" />
                    <TextColor A="255" B="0" G="0" R="0" />
                    <OutlineColor />
                    <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                    <ShadowColor />
                  </AbstractNodeData>
                  <AbstractNodeData Name="fb_share_panel" ActionTag="-1845582201" Tag="353" RotationSkewX="0" RotationSkewY="0" LeftMargin="467.322388" RightMargin="0.6776" TopMargin="32.9762" BottomMargin="39.0238" TouchEnable="True" BackColorAlpha="102" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
                    <Size Y="84" X="154" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0" />
                    <Position X="544.322388" Y="39.0238" />
                    <Scale ScaleX="1" ScaleY="1" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData />
                    <FirstColor A="255" B="255" G="200" R="150" />
                    <EndColor A="255" B="255" G="255" R="255" />
                    <ColorVector ScaleX="0" ScaleY="1" />
                    <SingleColor A="255" B="255" G="200" R="150" />
                    <Children>
                      <AbstractNodeData Name="bg" ActionTag="-2115164501" Tag="354" RotationSkewX="0" RotationSkewY="0" LeftMargin="23" RightMargin="19" TopMargin="44" BottomMargin="2" Alpha="204" LeftEage="20" RightEage="20" TopEage="10" BottomEage="10" Scale9OriginX="20" Scale9OriginY="10" Scale9Width="214" Scale9Height="10" Scale9Enable="True" ctype="ImageViewObjectData">
                        <Size Y="38" X="112" />
                        <AnchorPoint ScaleX="0.5" ScaleY="0" />
                        <Position X="79" Y="2" />
                        <Scale ScaleX="1" ScaleY="1" />
                        <CColor A="255" B="255" G="255" R="255" />
                        <FileData Type="PlistSubImage" Path="bg/weaponbox_infobg2_d.png" Plist="ui.plist" />
                      </AbstractNodeData>
                      <AbstractNodeData Name="reward_num" ActionTag="1109622507" Tag="355" RotationSkewX="0" RotationSkewY="0" LeftMargin="55" RightMargin="81" TopMargin="55.000099" BottomMargin="6.9999" FontSize="20" LabelText="88
" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                        <Size Y="22" X="18" />
                        <AnchorPoint ScaleX="1" ScaleY="0.5" />
                        <Position X="73" Y="17.999901" />
                        <Scale ScaleX="1" ScaleY="1" />
                        <CColor A="255" B="255" G="255" R="255" />
                        <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                        <OutlineColor />
                        <ShadowColor />
                      </AbstractNodeData>
                      <AbstractNodeData Name="fb_share_btn" ActionTag="1055881739" Tag="481" RotationSkewX="0" RotationSkewY="0" LeftMargin="-2" RightMargin="-6" TopMargin="-5" BottomMargin="23" TouchEnable="True" Scale9Enable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="138" Scale9Height="60" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
                        <Size Y="66" X="162" />
                        <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                        <Position X="79" Y="56" />
                        <Scale ScaleX="0.7" ScaleY="0.7" />
                        <CColor A="255" B="255" G="255" R="255" />
                        <NormalFileData Type="PlistSubImage" Path="button/fb_share_btn.png" Plist="ui.plist" />
                        <PressedFileData Type="PlistSubImage" Path="button/fb_share_btn.png" Plist="ui.plist" />
                        <DisabledFileData Type="PlistSubImage" Path="button/fb_share_btn.png" Plist="ui.plist" />
                        <TextColor A="255" B="70" G="65" R="65" />
                        <OutlineColor />
                        <FontResource />
                        <ShadowColor />
                      </AbstractNodeData>
                      <AbstractNodeData Name="reward_icon" ActionTag="-547551785" Tag="358" RotationSkewX="0" RotationSkewY="0" LeftMargin="77" RightMargin="45" TopMargin="49.000099" BottomMargin="2.9999" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="32" Scale9Height="32" ctype="ImageViewObjectData">
                        <Size Y="32" X="32" />
                        <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                        <Position X="93" Y="18.999901" />
                        <Scale ScaleX="0.7" ScaleY="0.7" />
                        <CColor A="255" B="255" G="255" R="255" />
                        <FileData Type="PlistSubImage" Path="icon/resource/blood_diamond_header.png" Plist="icon.plist" />
                      </AbstractNodeData>
                    </Children>
                  </AbstractNodeData>
                  <AbstractNodeData Name="completed_bg" ActionTag="1803116603" Tag="207" RotationSkewX="0" RotationSkewY="0" LeftMargin="526.999878" RightMargin="-580.999878" TopMargin="-107.000298" BottomMargin="53.000301" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="54" Scale9Height="54" ctype="ImageViewObjectData">
                    <Size Y="54" X="54" />
                    <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                    <Position X="553.999878" Y="80.000298" />
                    <Scale ScaleX="2" ScaleY="2" />
                    <CColor A="255" B="255" G="255" R="255" />
                    <FileData Type="PlistSubImage" Path="bg/spec_roundbg.png" Plist="ui.plist" />
                    <Children>
                      <AbstractNodeData Name="icon" ActionTag="1075114597" Tag="208" RotationSkewX="0" RotationSkewY="0" LeftMargin="-12.5" RightMargin="-13.5" TopMargin="-5" BottomMargin="-5" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="80" Scale9Height="64" ctype="ImageViewObjectData">
                        <Size Y="64" X="80" />
                        <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                        <Position X="27.5" Y="27" />
                        <Scale ScaleX="0.5" ScaleY="0.5" />
                        <CColor A="255" B="255" G="255" R="255" />
                        <FileData Type="PlistSubImage" Path="icon/global/equipped.png" Plist="ui.plist" />
                      </AbstractNodeData>
                    </Children>
                  </AbstractNodeData>
                </Children>
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="pic1" ActionTag="-146080345" Tag="178" RotationSkewX="0" RotationSkewY="0" LeftMargin="-0.0002" RightMargin="0.0002" TopMargin="-23.997601" BottomMargin="1050.997559" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
            <Size Y="109" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0" />
            <Position X="319.999786" Y="1050.997559" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="pic2" ActionTag="1375297367" Tag="179" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="992.000122" BottomMargin="-81.000099" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="90" Scale9Height="32" ctype="ImageViewObjectData">
            <Size Y="225" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="1" />
            <Position X="320" Y="143.999893" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/box_n_detail_bg.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="up_border" ActionTag="130316591" Tag="180" RotationSkewX="0" RotationSkewY="0" LeftMargin="-0.0002" RightMargin="0.0002" TopMargin="63.001301" BottomMargin="948.998718" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="320" Scale9Height="62" ctype="ImageViewObjectData">
            <Size Y="124" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="319.999786" Y="1010.998718" />
            <Scale ScaleX="1" ScaleY="-1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/herodetail_border_d.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="dpwn_border" ActionTag="1452125733" Tag="181" RotationSkewX="0" RotationSkewY="0" LeftMargin="0" RightMargin="0" TopMargin="902" BottomMargin="120" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="320" Scale9Height="62" ctype="ImageViewObjectData">
            <Size Y="114" X="640" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="177" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="border/herodetail_border_d.png" Plist="ui.plist" />
          </AbstractNodeData>
          <AbstractNodeData Name="title_bg" ActionTag="68153084" Tag="182" RotationSkewX="0" RotationSkewY="0" LeftMargin="184.5" RightMargin="184.5" TopMargin="45.503899" BottomMargin="1033.496094" LeftEage="81" RightEage="81" TopEage="0" BottomEage="0" Scale9OriginX="81" Scale9OriginY="0" Scale9Width="29" Scale9Height="57" Scale9Enable="True" ctype="ImageViewObjectData">
            <Size Y="57" X="271" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="320" Y="1061.996094" />
            <Scale ScaleX="2" ScaleY="2" />
            <CColor A="255" B="255" G="255" R="255" />
            <FileData Type="PlistSubImage" Path="bg/maintitle_bg.png" Plist="ui.plist" />
            <Children>
              <AbstractNodeData Name="name" ActionTag="-664922297" Tag="183" RotationSkewX="0" RotationSkewY="0" LeftMargin="39.3326" RightMargin="39.6674" TopMargin="19.0002" BottomMargin="2.9998" FontSize="32" LabelText="成 就" OutlineSize="1" ShadowOffsetX="2" ShadowOffsetY="-2" ctype="TextObjectData">
                <Size Y="35" X="80" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="135.332596" Y="20.4998" />
                <Scale ScaleX="0.5" ScaleY="0.5" />
                <CColor A="255" B="255" G="255" R="255" />
                <FontResource Type="Normal" Path="fonts/general.ttf" Plist="" />
                <OutlineColor />
                <ShadowColor />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="back_btn" ActionTag="759629029" Tag="184" RotationSkewX="0" RotationSkewY="0" LeftMargin="-79.357597" RightMargin="486.357605" TopMargin="928" BottomMargin="134" TouchEnable="True" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="233" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="" FontSize="14" ctype="ButtonObjectData">
            <Size Y="74" X="233" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="37.142399" Y="171" />
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
              <AbstractNodeData Name="back_icon" ActionTag="-381357580" Tag="185" RotationSkewX="0" RotationSkewY="0" LeftMargin="97.5" RightMargin="42.5" TopMargin="27" BottomMargin="23" LeftEage="0" RightEage="0" TopEage="0" BottomEage="0" Scale9OriginX="0" Scale9OriginY="0" Scale9Width="93" Scale9Height="24" ctype="ImageViewObjectData">
                <Size Y="24" X="93" />
                <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
                <Position X="144" Y="35" />
                <Scale ScaleX="1" ScaleY="1" />
                <CColor A="255" B="255" G="255" R="255" />
                <FileData Type="PlistSubImage" Path="button/backbtn_icon.png" Plist="ui.plist" />
              </AbstractNodeData>
            </Children>
          </AbstractNodeData>
          <AbstractNodeData Name="google_btn" ActionTag="203335493" Tag="108" RotationSkewX="0" RotationSkewY="0" LeftMargin="173" RightMargin="171" TopMargin="925.285828" BottomMargin="136.714203" TouchEnable="True" Scale9Enable="True" LeftEage="81" RightEage="81" TopEage="0" BottomEage="0" Scale9OriginX="81" Scale9OriginY="0" Scale9Width="122" Scale9Height="74" ShadowOffsetX="2" ShadowOffsetY="-2" ButtonText="Google Game" FontSize="28" ctype="ButtonObjectData">
            <Size Y="74" X="296" />
            <AnchorPoint ScaleX="0.5" ScaleY="0.5" />
            <Position X="321" Y="173.714203" />
            <Scale ScaleX="1" ScaleY="1" />
            <CColor A="255" B="255" G="255" R="255" />
            <NormalFileData Type="PlistSubImage" Path="button/buttonbg_1.png" Plist="ui.plist" />
            <PressedFileData Type="PlistSubImage" Path="button/buttonbg_1.png" Plist="ui.plist" />
            <DisabledFileData Type="PlistSubImage" Path="button/buttonbg_1.png" Plist="ui.plist" />
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
