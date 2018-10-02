#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Radio2Fichier
# Generated: Fri Sep 28 11:01:54 2018
##################################################

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print "Warning: failed to XInitThreads()"

from PyQt4 import Qt
from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import qtgui
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from gnuradio.qtgui import Range, RangeWidget
from optparse import OptionParser
import sip
import sys
import time
from gnuradio import qtgui


class radio2fichier(gr.top_block, Qt.QWidget):

    def __init__(self, address="serial=ECR10ZFB1", antenna='RX2', filename="../recv_spls.bin", freq=868e6, gain=20, samp_rate=1e6):
        gr.top_block.__init__(self, "Radio2Fichier")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("Radio2Fichier")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "radio2fichier")
        self.restoreGeometry(self.settings.value("geometry").toByteArray())


        ##################################################
        # Parameters
        ##################################################
        self.address = address
        self.antenna = antenna
        self.filename = filename
        self.freq = freq
        self.gain = gain
        self.samp_rate = samp_rate

        ##################################################
        # Variables
        ##################################################
        self.variable_samp_rate = variable_samp_rate = samp_rate
        self.variable_gain = variable_gain = gain
        self.variable_freq = variable_freq = freq

        ##################################################
        # Blocks
        ##################################################
        self._variable_samp_rate_tool_bar = Qt.QToolBar(self)
        self._variable_samp_rate_tool_bar.addWidget(Qt.QLabel("variable_samp_rate"+": "))
        self._variable_samp_rate_line_edit = Qt.QLineEdit(str(self.variable_samp_rate))
        self._variable_samp_rate_tool_bar.addWidget(self._variable_samp_rate_line_edit)
        self._variable_samp_rate_line_edit.returnPressed.connect(
        	lambda: self.set_variable_samp_rate(eng_notation.str_to_num(str(self._variable_samp_rate_line_edit.text().toAscii()))))
        self.top_layout.addWidget(self._variable_samp_rate_tool_bar)
        self._variable_gain_range = Range(0, 50, 1, gain, 200)
        self._variable_gain_win = RangeWidget(self._variable_gain_range, self.set_variable_gain, "variable_gain", "counter_slider", float)
        self.top_layout.addWidget(self._variable_gain_win)
        self._variable_freq_tool_bar = Qt.QToolBar(self)
        self._variable_freq_tool_bar.addWidget(Qt.QLabel("variable_freq"+": "))
        self._variable_freq_line_edit = Qt.QLineEdit(str(self.variable_freq))
        self._variable_freq_tool_bar.addWidget(self._variable_freq_line_edit)
        self._variable_freq_line_edit.returnPressed.connect(
        	lambda: self.set_variable_freq(eng_notation.str_to_num(str(self._variable_freq_line_edit.text().toAscii()))))
        self.top_layout.addWidget(self._variable_freq_tool_bar)
        self.uhd_usrp_source_0 = uhd.usrp_source(
        	",".join((address, "")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_source_0.set_samp_rate(variable_samp_rate)
        self.uhd_usrp_source_0.set_center_freq(variable_freq, 0)
        self.uhd_usrp_source_0.set_gain(variable_gain, 0)
        self.uhd_usrp_source_0.set_antenna(antenna, 0)
        self.qtgui_freq_sink_x_0 = qtgui.freq_sink_c(
        	1024, #size
        	firdes.WIN_BLACKMAN_hARRIS, #wintype
        	0, #fc
        	samp_rate, #bw
        	"", #name
        	1 #number of inputs
        )
        self.qtgui_freq_sink_x_0.set_update_time(0.10)
        self.qtgui_freq_sink_x_0.set_y_axis(-140, 10)
        self.qtgui_freq_sink_x_0.set_y_label('Relative Gain', 'dB')
        self.qtgui_freq_sink_x_0.set_trigger_mode(qtgui.TRIG_MODE_FREE, 0.0, 0, "")
        self.qtgui_freq_sink_x_0.enable_autoscale(False)
        self.qtgui_freq_sink_x_0.enable_grid(False)
        self.qtgui_freq_sink_x_0.set_fft_average(1.0)
        self.qtgui_freq_sink_x_0.enable_axis_labels(True)
        self.qtgui_freq_sink_x_0.enable_control_panel(False)

        if not True:
          self.qtgui_freq_sink_x_0.disable_legend()

        if "complex" == "float" or "complex" == "msg_float":
          self.qtgui_freq_sink_x_0.set_plot_pos_half(not True)

        labels = ['', '', '', '', '',
                  '', '', '', '', '']
        widths = [1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1]
        colors = ["blue", "red", "green", "black", "cyan",
                  "magenta", "yellow", "dark red", "dark green", "dark blue"]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
                  1.0, 1.0, 1.0, 1.0, 1.0]
        for i in xrange(1):
            if len(labels[i]) == 0:
                self.qtgui_freq_sink_x_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_freq_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_freq_sink_x_0.set_line_width(i, widths[i])
            self.qtgui_freq_sink_x_0.set_line_color(i, colors[i])
            self.qtgui_freq_sink_x_0.set_line_alpha(i, alphas[i])

        self._qtgui_freq_sink_x_0_win = sip.wrapinstance(self.qtgui_freq_sink_x_0.pyqwidget(), Qt.QWidget)
        self.top_layout.addWidget(self._qtgui_freq_sink_x_0_win)
        self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_gr_complex*1, filename, False)
        self.blocks_file_sink_0.set_unbuffered(False)



        ##################################################
        # Connections
        ##################################################
        self.connect((self.uhd_usrp_source_0, 0), (self.blocks_file_sink_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.qtgui_freq_sink_x_0, 0))

    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "radio2fichier")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_address(self):
        return self.address

    def set_address(self, address):
        self.address = address

    def get_antenna(self):
        return self.antenna

    def set_antenna(self, antenna):
        self.antenna = antenna
        self.uhd_usrp_source_0.set_antenna(self.antenna, 0)

    def get_filename(self):
        return self.filename

    def set_filename(self, filename):
        self.filename = filename
        self.blocks_file_sink_0.open(self.filename)

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.set_variable_freq(self.freq)

    def get_gain(self):
        return self.gain

    def set_gain(self, gain):
        self.gain = gain
        self.set_variable_gain(self.gain)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.set_variable_samp_rate(self.samp_rate)
        self.qtgui_freq_sink_x_0.set_frequency_range(0, self.samp_rate)

    def get_variable_samp_rate(self):
        return self.variable_samp_rate

    def set_variable_samp_rate(self, variable_samp_rate):
        self.variable_samp_rate = variable_samp_rate
        Qt.QMetaObject.invokeMethod(self._variable_samp_rate_line_edit, "setText", Qt.Q_ARG("QString", eng_notation.num_to_str(self.variable_samp_rate)))
        self.uhd_usrp_source_0.set_samp_rate(self.variable_samp_rate)

    def get_variable_gain(self):
        return self.variable_gain

    def set_variable_gain(self, variable_gain):
        self.variable_gain = variable_gain
        self.uhd_usrp_source_0.set_gain(self.variable_gain, 0)


    def get_variable_freq(self):
        return self.variable_freq

    def set_variable_freq(self, variable_freq):
        self.variable_freq = variable_freq
        Qt.QMetaObject.invokeMethod(self._variable_freq_line_edit, "setText", Qt.Q_ARG("QString", eng_notation.num_to_str(self.variable_freq)))
        self.uhd_usrp_source_0.set_center_freq(self.variable_freq, 0)


def argument_parser():
    parser = OptionParser(usage="%prog: [options]", option_class=eng_option)
    parser.add_option(
        "-a", "--address", dest="address", type="string", default="serial=ECR10ZFB1",
        help="Set serial=ECR10ZFB1 [default=%default]")
    parser.add_option(
        "-A", "--antenna", dest="antenna", type="string", default='RX2',
        help="Set Antenna [default=%default]")
    parser.add_option(
        "-n", "--filename", dest="filename", type="string", default="../recv_spls.bin",
        help="Set File Name [default=%default]")
    parser.add_option(
        "-f", "--freq", dest="freq", type="eng_float", default=eng_notation.num_to_str(868e6),
        help="Set Default Frequency [default=%default]")
    parser.add_option(
        "-g", "--gain", dest="gain", type="eng_float", default=eng_notation.num_to_str(20),
        help="Set Set gain in dB (default is midpoint) [default=%default]")
    parser.add_option(
        "-s", "--samp-rate", dest="samp_rate", type="eng_float", default=eng_notation.num_to_str(1e6),
        help="Set Sample Rate [default=%default]")
    return parser


def main(top_block_cls=radio2fichier, options=None):
    if options is None:
        options, _ = argument_parser().parse_args()

    from distutils.version import StrictVersion
    if StrictVersion(Qt.qVersion()) >= StrictVersion("4.5.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls(address=options.address, antenna=options.antenna, filename=options.filename, freq=options.freq, gain=options.gain, samp_rate=options.samp_rate)
    tb.start()
    tb.show()

    def quitting():
        tb.stop()
        tb.wait()
    qapp.connect(qapp, Qt.SIGNAL("aboutToQuit()"), quitting)
    qapp.exec_()


if __name__ == '__main__':
    main()
