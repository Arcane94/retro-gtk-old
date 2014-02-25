/* retro_library.c
 * Copyright (c) 2014, Adrien Plazas, All rights reserved.
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.
 */

#include "retro_library.h"

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <dlfcn.h>

int create_temporary_file (retro_library_t *library);
void file_copy (const char *src, const char *dst);
void set_functions (retro_library_t *library);

retro_library_t *retro_library_new (char *shared_object) {
	retro_library_t *library = (retro_library_t *) malloc (sizeof (retro_library_t));
	
	library->src_name = strdup (shared_object);
	
	int tmp_descriptor = create_temporary_file (library);
	file_copy (shared_object, library->tmp_name);
	
	library->handle = dlopen (library->tmp_name, RTLD_NOW);
	
	close (tmp_descriptor);
	
	if (! library->handle) fprintf (stderr, "%s: %s\n", shared_object, dlerror ());
	
	set_functions (library);
	
	return library;
}

void retro_library_free (retro_library_t *library) {
	if (library) {
		if (library->handle) {
			dlclose (library->handle);
		}
		
		if (library->tmp_name) {
			unlink (library->tmp_name);
			free (library->tmp_name);
		}
		
		if (library->src_name) {
			free (library->src_name);
		}
		
		free (library);
	}
}

void retro_library_set_environment(retro_library_t *library, retro_environment_t environment) {
	library->set_environment (environment);
}

void retro_library_set_video_refresh(retro_library_t *library, retro_video_refresh_t video_refresh) {
	library->set_video_refresh (video_refresh);
}

void retro_library_set_audio_sample(retro_library_t *library, retro_audio_sample_t audio_sample) {
	library->set_audio_sample (audio_sample);
}

void retro_library_set_audio_sample_batch(retro_library_t *library, retro_audio_sample_batch_t audio_sample_batch) {
	library->set_audio_sample_batch (audio_sample_batch);
}

void retro_library_set_input_poll(retro_library_t *library, retro_input_poll_t input_poll) {
	library->set_input_poll (input_poll);
}

void retro_library_set_input_state(retro_library_t *library, retro_input_state_t input_state) {
	library->set_input_state (input_state);
}

void retro_library_init(retro_library_t *library) {
	library->init ();
}

void retro_library_deinit(retro_library_t *library) {
	library->deinit ();
}

unsigned retro_library_api_version(retro_library_t *library) {
	return library->api_version ();
}

void retro_library_get_system_info(retro_library_t *library, struct retro_system_info *info) {
	library->get_system_info (info);
}

void retro_library_get_system_av_info(retro_library_t *library, struct retro_system_av_info *info) {
	library->get_system_av_info (info);
}

void retro_library_reset(retro_library_t *library) {
	library->reset ();
}

void retro_library_run(retro_library_t *library) {
	library->run ();
}

bool retro_library_load_game(retro_library_t *library, const struct retro_game_info *game) {
	return library->load_game (game);
}

// Helper hunctions

int create_temporary_file (retro_library_t *library) {
	const char *template = "/tmp/retro-library-XXXXXX";
	
	library->tmp_name = strdup (template);
	
	return mkstemp (library->tmp_name);
}

void file_copy (const char *src, const char *dst) {
	int src_desc = open (src, O_RDONLY);
	int dst_desc = open (dst, O_WRONLY);
	
	char buffer[4096];
	ssize_t count;
	
	while ((count = read (src_desc, buffer, 4096))) {
		write (dst_desc, buffer, count);
	}
	
	close (src_desc);
	close (dst_desc);
}

void set_functions (retro_library_t *library) {
	library->set_environment =
	(retro_library_set_environment_t) dlsym (library->handle, "retro_set_environment");
	
	library->set_video_refresh  =
	(retro_library_set_video_refresh_t) dlsym (library->handle, "retro_set_video_refresh");
	
	library->set_audio_sample =
	(retro_library_set_audio_sample_t) dlsym (library->handle, "retro_set_audio_sample");
	
	library->set_audio_sample_batch =
	(retro_library_set_audio_sample_batch_t) dlsym (library->handle, "retro_set_audio_sample_batch");
	
	library->set_input_poll =
	(retro_library_set_input_poll_t) dlsym (library->handle, "retro_set_input_poll");
	
	library->set_input_state =
	(retro_library_set_input_state_t) dlsym (library->handle, "retro_set_input_state");
	
	library->init =
	(retro_library_init_t) dlsym (library->handle, "retro_init");
	
	library->deinit =
	(retro_library_deinit_t) dlsym (library->handle, "retro_deinit");
	
	library->api_version =
	(retro_library_api_version_t) dlsym (library->handle, "retro_api_version");
	
	library->get_system_info =
	(retro_library_get_system_info_t) dlsym (library->handle, "retro_get_system_info");
	
	library->get_system_av_info =
	(retro_library_get_system_av_info_t) dlsym (library->handle, "retro_get_system_av_info");
	
	library->set_controller_port_device =
	(retro_library_set_controller_port_device_t) dlsym (library->handle, "retro_set_controller_port_device");
	
	library->reset =
	(retro_library_reset_t) dlsym (library->handle, "retro_reset");
	
	library->run =
	(retro_library_run_t) dlsym (library->handle, "retro_run");
	
	library->serialize_size =
	(retro_library_serialize_size_t) dlsym (library->handle, "retro_serialize_size");
	
	library->serialize =
	(retro_library_serialize_t) dlsym (library->handle, "retro_serialize");
	
	library->unserialize =
	(retro_library_unserialize_t) dlsym (library->handle, "retro_unserialize");
	
	library->cheat_reset =
	(retro_library_cheat_reset_t) dlsym (library->handle, "retro_cheat_reset");
	
	library->cheat_set =
	(retro_library_cheat_set_t) dlsym (library->handle, "retro_cheat_set");
	
	library->load_game =
	(retro_library_load_game_t) dlsym (library->handle, "retro_load_game");
	
	library->load_game_special =
	(retro_library_load_game_special_t) dlsym (library->handle, "retro_load_game_special");
	
	library->unload_game =
	(retro_library_unload_game_t) dlsym (library->handle, "retro_unload_game");
	
	library->get_region =
	(retro_library_get_region_t) dlsym (library->handle, "retro_get_region");
	
	library->get_memory_data =
	(retro_library_get_memory_data_t) dlsym (library->handle, "retro_get_memory_data");
	
	library->get_memory_size =
	(retro_library_get_memory_size_t) dlsym (library->handle, "retro_get_memory_size");
}

