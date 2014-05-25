--[[

  ��LAN�l�b�g���[�N�̃z�X�g�̗����擾�X�N���v�g
�@�@DHCPD��SYSLOG���Ď����A���o�����瓖�Y��SYSLOG�Ɛڑ��|�[�g��
�@�@SYSLOG�ɏo�͂��܂��B

  ��������
  �E���̃t�@�C���� RTFS ���O���������ɕۑ����Ă��������B
  �E�X�N���v�g���~����Ƃ��� terminate lua �R�}���h�����s���Ă��������B
  �E�ēx�ALua �X�N���v�g�����s����ꍇ�� lua �R�}���h�Ŏ��s���Ă��������B
  �E���}�[�N�̕t�����ݒ�l�͕ύX���\�ł��B

  ���m�[�g��
�@�Eshow log | grep "Host detect" �Ŏ��s���ʂ̈ꗗ���擾�ł��܂��B
�@�E�{�X�N���v�g���o�͂��� SYSLOG ���x�����w�肷�邱�Ƃ��ł��܂��B
�@�@SYSLOG �̃��x�����w�肷��ɂ́Alog_level ��ݒ肵�Ă��������B
�@�@debug ���x���Anotice ���x���� SYSLOG ���o�͂��邽�߂ɂ́A���ꂼ��ȉ��̐ݒ�
�@�@���K�v�ł��B
�@�@�@debug ���x�� ��� syslog debug on
�@�@�@notice ���x����� syslog notice on
�@�E�{�X�N���v�g�t�@�C����ҏW����ꍇ�A�����R�[�h�͕K�� Shift-JIS ���g�p���Ă�
�@�@�������B

]]

--------------------------##  �ݒ�l  ##--------------------------------

-- ���o������ SYSLOG �̕�����p�^�[��
ptn = "%[DHCPD%]"

-- MAC�A�h���X���o�̕�����p�^�[��
mac_ptn = "%x%x:%x%x:%x%x:%x%x:%x%x:%x%x"

-- �o�͂��� SYSLOG �̃��x�� (info, debug, notice)
log_level = "notice"		-- ��

------------------------------------------------------------
-- �z�X�g����                                             --
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
-- ���C�����[�`��                                         --
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

