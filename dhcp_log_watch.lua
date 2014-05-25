--[[

  ●LANネットワークのホストの履歴取得スクリプト
　　DHCPDのSYSLOGを監視し、検出したら当該のSYSLOGと接続ポートを
　　SYSLOGに出力します。

  ＜説明＞
  ・このファイルを RTFS か外部メモリに保存してください。
  ・スクリプトを停止するときは terminate lua コマンドを実行してください。
  ・再度、Lua スクリプトを実行する場合は lua コマンドで実行してください。
  ・★マークの付いた設定値は変更が可能です。

  ＜ノート＞
　・show log | grep "Host detect" で実行結果の一覧を取得できます。
　・本スクリプトが出力する SYSLOG レベルを指定することができます。
　　SYSLOG のレベルを指定するには、log_level を設定してください。
　　debug レベル、notice レベルの SYSLOG を出力するためには、それぞれ以下の設定
　　が必要です。
　　　debug レベル ･･･ syslog debug on
　　　notice レベル･･･ syslog notice on
　・本スクリプトファイルを編集する場合、文字コードは必ず Shift-JIS を使用してく
　　ださい。

]]

--------------------------##  設定値  ##--------------------------------

-- 検出したい SYSLOG の文字列パターン
ptn = "%[DHCPD%]"

-- MACアドレス検出の文字列パターン
mac_ptn = "%x%x:%x%x:%x%x:%x%x:%x%x:%x%x"

-- 出力する SYSLOG のレベル (info, debug, notice)
log_level = "notice"		-- ★

------------------------------------------------------------
-- ホスト検索                                             --
------------------------------------------------------------
function search_host(mac)

        sw_route = nil
        route = nil
        port = nil

        rtn, str = rt.command("show status switching-hub macaddress " .. mac)
        port = string.match(str, "port (%d):")
        if (port) then
                route = "LAN1"
        else
                rtn, str = rt.command("show arp lan2")
                if (string.match(str, mac)) then
                        route = "LAN2"
                else
                        rtn, str = rt.command("show arp lan3")
                        if (string.match(str, mac)) then
                                route = "LAN3"
                        end
                end
        end

        return route, port
end

------------------------------------------------------------
-- メインルーチン                                         --
------------------------------------------------------------
local rtn, str
local buf

while (true) do
        rtn, str = rt.syslogwatch(ptn)
        mac = string.match(str[1], mac_ptn)
        if (mac) then
                route, port = search_host(mac)
                if (route) then
                        buf = str[1]
                        buf = buf .. " at " .. route
                        if (port) then
                                buf = buf .. " : port " .. port
                        end
                        rt.syslog(log_level, "[Lua] Host detect " .. buf)
                end
        end
end

