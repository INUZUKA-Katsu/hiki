! �Ȥ���
hiki.cgi �Τ���ǥ��쥯�ȥ�� misc/plugin/attach/attach.cgi ��
���ԡ����ޤ����ޤ���
misc/plugin �ǥ��쥯�ȥ�� misc/plugin/attach/attach.rb ��
���ԡ����뤫��symlink ��ĥ��ޤ���
���θ塢�ִ�����->�֥ץ饰��������פ� attach.rb ��ͭ���ˤ��Ʋ�������

!! HikiFarm ��
�嵭�μ��˲ä��ơ����Τ����줫����ˡ�ǻȤ��ޤ���

!!! (A) �ե��������
  $ cat attach.cgi
  #!/usr/bin/env ruby
  hiki=''
  eval( open( '../hikifarm.conf' ){|f|f.read.untaint} )
  $:.unshift "#{hiki}"
  load "#{hiki}/misc/plugin/attach.cgi"

�Τ褦�� attach.cgi �򡢳� Hiki �Τ��� CGI �Υǥ��쥯�ȥ���֤��Ƥ���������

!!! (B) symlink ����
hiki.cgi �˥��ԡ����� attach.cgi ���� symlink ���֤��Ƥ���������
(ľ�� misc/plugin/attach/attach.cgi ���� symlink ��Ϥä��顢�饤�֥��
�����ɤǤ��ʤ��Τ�ư��ޤ���)
