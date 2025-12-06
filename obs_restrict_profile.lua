---
-- Script Name: Restrict Profile
-- Author: jessanya
-- Version: 0.9
-- Description: Forces specific scene when profile is selected
---

obs = obslua

local logging = false

function script_properties()
  local props = obs.obs_properties_create()

  local profiles = obs.obs_frontend_get_profiles()
  local profile_list = obs.obs_properties_add_list(props, "target_profile", "Block Profile",
  obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

  for _, profile in ipairs(profiles) do
    obs.obs_property_list_add_string(profile_list, profile, profile)
  end

  forced_prop = obs.obs_properties_add_text(props, "forced_scene", "Forced Scene", obs.OBS_TEXT_DEFAULT)
  label_prop = obs.obs_properties_add_text(props, "label", "", obs.OBS_TEXT_INFO)

  obs.obs_property_set_modified_callback(forced_prop, on_forced_scene_changed)
  on_forced_scene_changed(props)

  return props
end

my_settings = nil
function script_update(settings)
  my_settings = settings
  target_profile = obs.obs_data_get_string(settings, "target_profile")
  forced_scene = obs.obs_data_get_string(settings, "forced_scene")
  check()
end

function on_forced_scene_changed(props)
  local newlabel = "Scene not found"
  local scenes = obs.obs_frontend_get_scenes()
  for _, scene in ipairs(scenes) do
    if obs.obs_source_get_name(scene) == forced_scene then
      newlabel = ""
    end
  end
  obs.source_list_release(scenes)
  obs.obs_property_set_description(label_prop, newlabel)
  return true
end

function check()
  local current_profile = obs.obs_frontend_get_current_profile()
  local current_scene = obs.obs_frontend_get_current_scene()

  if current_profile then
    if current_profile == target_profile then
      if logging then
        obs.script_log(obs.LOG_INFO, "Profile matches. Switching to black")
      end
      if obs.obs_source_get_name(current_scene) == forced_scene then
        if logging then
          obs.script_log(obs.LOG_INFO, "Already on scene")
        end
      else
        local scenes = obs.obs_frontend_get_scenes()
        for _, scene in ipairs(scenes) do
          if obs.obs_source_get_name(scene) == forced_scene then
            obs.obs_frontend_set_current_scene(scene)
            break
          end
        end
        obs.source_list_release(scenes)
      end
    end
  end

  obs.obs_source_release(current_scene)
end

function on_event(event)
  if event == obs.OBS_FRONTEND_EVENT_PROFILE_CHANGED or event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
    if logging then
      obs.script_log(obs.LOG_INFO, "Profile Changed")
    end
    check()
  end
end

function script_load(settings)
  obs.obs_frontend_add_event_callback(on_event)
  check()
end

function script_unload()
    obs.obs_frontend_remove_event_callback(on_event)
    my_settings = nil
    target_profile = nil
    forced_scene = nil
end

function script_description()
  return "Forces use of specific Scene when selected Profile is set. Add script to Scene Collection you want to prevent the use of Profile with"
end

