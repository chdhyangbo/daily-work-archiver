import { logger } from '../utils/logger.js';

export function notifyUser(title: string, message: string): void {
  logger.section('Desktop Notification');
  logger.info(`Title: ${title}`);
  logger.info(`Message: ${message}`);
  
  // Windows toast notification (simplified)
  try {
    const { execSync } = require('child_process');
    const psCommand = `[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null;
      $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);
      $template.GetElementsByTagName('text')[0].AppendChild($template.CreateTextNode('${title}')) | Out-Null;
      $template.GetElementsByTagName('text')[1].AppendChild($template.CreateTextNode('${message}')) | Out-Null;
      $toast = [Windows.UI.Notifications.ToastNotification]::new($template);
      [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('tools-ng').Show($toast);`;
    
    execSync(`powershell -Command "${psCommand}"`, { stdio: 'ignore' });
    logger.success('Notification sent');
  } catch (error) {
    logger.warn('Could not send desktop notification (Windows only)');
  }
}
