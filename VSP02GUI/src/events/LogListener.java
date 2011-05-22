/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package events;

import java.util.EventListener;

/**
 *
 * @author corpsi
 */
public interface LogListener extends EventListener {
  void log(String msg);
}
