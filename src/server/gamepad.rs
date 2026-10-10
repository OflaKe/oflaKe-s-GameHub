use base::message_proto::XboxGamepadEvent;
use vigem_client::{Client, TargetId, XButtons, XGamepad, XTarget};
use std::{fs::OpenOptions, io::Write, sync::atomic::{AtomicUsize, Ordering}};

static TRACED_EVENTS: AtomicUsize = AtomicUsize::new(0);

pub(crate) fn trace_received(buttons: u32, keyboard_enabled: bool) {
    if TRACED_EVENTS.fetch_add(1, Ordering::Relaxed) < 8 {
        trace(&format!("host received event: buttons=0x{buttons:04x}, keyboard_enabled={keyboard_enabled}"));
    }
}

fn trace(message: &str) {
    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open(r"C:\ProgramData\RustDeskXboxDiag.log")
    {
        let _ = writeln!(file, "{:?} {message}", std::time::SystemTime::now());
    }
}

#[derive(Default)]
pub(crate) struct XboxGamepad {
    target: Option<XTarget>,
    unavailable: bool,
}

impl XboxGamepad {
    pub(crate) fn update(&mut self, event: &XboxGamepadEvent) {
        if self.target.is_none() && !self.unavailable {
            trace("attempting ViGEm Xbox 360 target connection");
            self.target = Self::connect();
            self.unavailable = self.target.is_none();
        }

        let Some(target) = self.target.as_mut() else {
            return;
        };

        let report = XGamepad {
            buttons: XButtons((event.buttons & 0xFFFF) as u16),
            left_trigger: event.left_trigger.min(255) as u8,
            right_trigger: event.right_trigger.min(255) as u8,
            thumb_lx: event.left_x.clamp(i16::MIN as i32, i16::MAX as i32) as i16,
            thumb_ly: event.left_y.clamp(i16::MIN as i32, i16::MAX as i32) as i16,
            thumb_rx: event.right_x.clamp(i16::MIN as i32, i16::MAX as i32) as i16,
            thumb_ry: event.right_y.clamp(i16::MIN as i32, i16::MAX as i32) as i16,
        };

        if let Err(error) = target.update(&report) {
            trace(&format!("ViGEm target update failed: {error:?}"));
            hbb_common::log::warn!("Xbox virtual gamepad update failed: {error:?}");
            self.target = None;
            self.unavailable = true;
        }
    }

    pub(crate) fn release(&mut self) {
        if let Some(target) = self.target.as_mut() {
            if let Err(error) = target.update(&XGamepad::default()) {
                hbb_common::log::warn!("Xbox virtual gamepad release failed: {error:?}");
                self.target = None;
                self.unavailable = true;
            }
        }
    }

    fn connect() -> Option<XTarget> {
        let result = (|| {
            let client = Client::connect()?;
            let mut target = XTarget::new(client, TargetId::XBOX360_WIRED);
            target.plugin()?;
            target.wait_ready()?;
            Ok::<_, vigem_client::Error>(target)
        })();

        match result {
            Ok(target) => {
                trace("ViGEm Xbox 360 target connected and ready");
                Some(target)
            }
            Err(error) => {
                trace(&format!("ViGEm connection failed: {error:?}"));
                hbb_common::log::warn!(
                    "Xbox virtual gamepad unavailable; install and start ViGEmBus: {error:?}"
                );
                None
            }
        }
    }
}
