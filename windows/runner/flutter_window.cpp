#include "flutter_window.h"

#include <optional>
#include <windowsx.h>
#include <dwmapi.h>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/standard_method_codec.h"
#include "flutter/method_channel.h"
#include "flutter/method_result.h"
#include "flutter/encodable_value.h"

#pragma comment(lib, "dwmapi.lib")

std::wstring current_window_title = L"Karasu Launcher";

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
  {
    return false;
  }

  RECT frame = GetClientArea();
#ifndef DWMWA_TRANSITIONS_FORCEDISABLED
#define DWMWA_TRANSITIONS_FORCEDISABLED 3
#endif

  BOOL value = FALSE;
  DwmSetWindowAttribute(GetHandle(), DWMWA_TRANSITIONS_FORCEDISABLED, &value, sizeof(value));

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "com.karasu256.karasu_launcher/window",
      &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler(
      [this](const flutter::MethodCall<> &call,
             std::unique_ptr<flutter::MethodResult<>> result)
      {
        if (call.method_name() == "updateWindowTitle")
        {
          const auto *arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments)
          {
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            if (title_it != arguments->end() && std::holds_alternative<std::string>(title_it->second))
            {
              std::string title_utf8 = std::get<std::string>(title_it->second);

              int wide_char_length = MultiByteToWideChar(CP_UTF8, 0, title_utf8.c_str(), -1, nullptr, 0);
              if (wide_char_length > 0)
              {
                std::wstring title_wide(wide_char_length, 0);
                MultiByteToWideChar(CP_UTF8, 0, title_utf8.c_str(), -1, &title_wide[0], wide_char_length);

                current_window_title = title_wide;
                SetWindowText(GetHandle(), title_wide.c_str());

                InvalidateRect(GetHandle(), NULL, TRUE);
              }
            }
          }
        }
        result->Success();
      });

  // Make sure the window is correctly fitted to the content
  RECT rect = GetClientArea();
  MoveWindow(flutter_controller_->view()->GetNativeWindow(),
             rect.left, rect.top,
             rect.right - rect.left, rect.bottom - rect.top, TRUE);

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      { this->Show(); });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy()
{
  if (flutter_controller_)
  {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept
{
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_)
  {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result)
    {
      return *result;
    }
  }
  switch (message)
  {
  case WM_FONTCHANGE:
    flutter_controller_->engine()->ReloadSystemFonts();
    break;
  case WM_SIZE:
  case WM_SIZING:
    if (flutter_controller_)
    {
      flutter_controller_->ForceRedraw();
    }
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
