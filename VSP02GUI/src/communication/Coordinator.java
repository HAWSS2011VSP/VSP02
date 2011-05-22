/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package communication;

/**
 *
 * @author corpsi
 */

import com.ericsson.otp.erlang.*;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class Coordinator {

  protected final String remoteNodeAddress;
  protected final OtpNode self;
  protected final OtpMbox mbox;
  protected final OtpErlangPid logger;

  public Coordinator(final String remoteNodeAddress, final OtpErlangPid logger) throws IOException {
    this.remoteNodeAddress = remoteNodeAddress;
    this.self = new OtpNode("gui", "foo");
    this.mbox = self.createMbox();
    this.logger = logger;
  }

  public void setValues(int procCountFrom, int procCountTo, int waitingFrom,
          int waitingTo, int timeout, int gcd) throws Exception {
    OtpErlangTuple innerMsg = new OtpErlangTuple(new OtpErlangObject[]{
      new OtpErlangInt(procCountFrom),
      new OtpErlangInt(procCountTo),
      new OtpErlangInt(waitingFrom),
      new OtpErlangInt(waitingTo),
      new OtpErlangInt(timeout),
      new OtpErlangInt(gcd)
    });

    OtpErlangTuple msg = new OtpErlangTuple(new OtpErlangObject[] {
      logger,
      new OtpErlangAtom("setvalues"),
      innerMsg
    });

    mbox.send("coordinator", remoteNodeAddress, msg);
  }

  public void setInitial() throws Exception {
    mbox.send("coordinator", remoteNodeAddress, new OtpErlangTuple(
      new OtpErlangObject[] {
        logger,
        new OtpErlangAtom("setinitial")
      }
    ));
  }

  public void setReady() throws Exception {
    mbox.send("coordinator", remoteNodeAddress, new OtpErlangTuple(
      new OtpErlangObject[] {
        logger,
        new OtpErlangAtom("setready")
      }
    ));
  }
}
