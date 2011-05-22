/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package communication;

import com.ericsson.otp.erlang.*;
import events.LogListener;
import java.io.IOException;
import java.util.logging.Level;

/**
 *
 * @author corpsi
 */

public class Logger extends Thread {

  protected final LogListener loggingHandler;
  protected final OtpNode self;
  protected final OtpMbox mbox;

  public Logger(LogListener listener) throws IOException {
    loggingHandler = listener;
    self = new OtpNode("logger", "foo");
    mbox = self.createMbox();
  }

  @Override
  public void run() {
    while(true) {
      try {
        OtpErlangObject msg = mbox.receive();
        if(msg instanceof OtpErlangString) {
          loggingHandler.log(((OtpErlangString)msg).stringValue());
        }

      } catch (Exception ex) {
        java.util.logging.Logger.getLogger(Logger.class.getName()).log(Level.SEVERE, null, ex);
      }
    }
  }

  public OtpErlangPid getPid() {
    return mbox.self();
  }
}
