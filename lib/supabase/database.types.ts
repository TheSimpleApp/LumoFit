export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      activities: {
        Row: {
          activity_type: string | null
          calories_burned: number | null
          completed_at: string | null
          created_at: string | null
          description: string | null
          duration_minutes: number | null
          event_id: string | null
          id: string
          place_id: string | null
          title: string
          trip_id: string | null
          user_id: string
          xp_earned: number | null
        }
        Insert: {
          activity_type?: string | null
          calories_burned?: number | null
          completed_at?: string | null
          created_at?: string | null
          description?: string | null
          duration_minutes?: number | null
          event_id?: string | null
          id?: string
          place_id?: string | null
          title: string
          trip_id?: string | null
          user_id: string
          xp_earned?: number | null
        }
        Update: {
          activity_type?: string | null
          calories_burned?: number | null
          completed_at?: string | null
          created_at?: string | null
          description?: string | null
          duration_minutes?: number | null
          event_id?: string | null
          id?: string
          place_id?: string | null
          title?: string
          trip_id?: string | null
          user_id?: string
          xp_earned?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "activities_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activities_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "saved_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activities_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      badges: {
        Row: {
          created_at: string | null
          description: string
          icon_name: string
          id: string
          name: string
          requirement_type: string
          requirement_value: number
          tier: string | null
          xp_reward: number | null
        }
        Insert: {
          created_at?: string | null
          description: string
          icon_name: string
          id?: string
          name: string
          requirement_type: string
          requirement_value: number
          tier?: string | null
          xp_reward?: number | null
        }
        Update: {
          created_at?: string | null
          description?: string
          icon_name?: string
          id?: string
          name?: string
          requirement_type?: string
          requirement_value?: number
          tier?: string | null
          xp_reward?: number | null
        }
        Relationships: []
      }
      challenges: {
        Row: {
          challenge_type: string | null
          created_at: string | null
          description: string
          end_date: string | null
          icon_name: string | null
          id: string
          is_active: boolean | null
          requirement_type: string
          requirement_value: number
          start_date: string | null
          title: string
          xp_reward: number | null
        }
        Insert: {
          challenge_type?: string | null
          created_at?: string | null
          description: string
          end_date?: string | null
          icon_name?: string | null
          id?: string
          is_active?: boolean | null
          requirement_type: string
          requirement_value: number
          start_date?: string | null
          title: string
          xp_reward?: number | null
        }
        Update: {
          challenge_type?: string | null
          created_at?: string | null
          description?: string
          end_date?: string | null
          icon_name?: string | null
          id?: string
          is_active?: boolean | null
          requirement_type?: string
          requirement_value?: number
          start_date?: string | null
          title?: string
          xp_reward?: number | null
        }
        Relationships: []
      }
      community_photos: {
        Row: {
          caption: string | null
          created_at: string | null
          flag_reason: string | null
          flagged: boolean | null
          id: string
          image_url: string
          moderation_status: string | null
          photo_type: string | null
          place_id: string
          user_id: string | null
        }
        Insert: {
          caption?: string | null
          created_at?: string | null
          flag_reason?: string | null
          flagged?: boolean | null
          id?: string
          image_url: string
          moderation_status?: string | null
          photo_type?: string | null
          place_id: string
          user_id?: string | null
        }
        Update: {
          caption?: string | null
          created_at?: string | null
          flag_reason?: string | null
          flagged?: boolean | null
          id?: string
          image_url?: string
          moderation_status?: string | null
          photo_type?: string | null
          place_id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "community_photos_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "saved_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "community_photos_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      events: {
        Row: {
          address: string | null
          category: string | null
          created_at: string | null
          description: string | null
          end_date: string | null
          external_id: string | null
          id: string
          latitude: number | null
          longitude: number | null
          registration_url: string | null
          start_date: string
          title: string
          venue_name: string
          website_url: string | null
        }
        Insert: {
          address?: string | null
          category?: string | null
          created_at?: string | null
          description?: string | null
          end_date?: string | null
          external_id?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          registration_url?: string | null
          start_date: string
          title: string
          venue_name: string
          website_url?: string | null
        }
        Update: {
          address?: string | null
          category?: string | null
          created_at?: string | null
          description?: string | null
          end_date?: string | null
          external_id?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          registration_url?: string | null
          start_date?: string
          title?: string
          venue_name?: string
          website_url?: string | null
        }
        Relationships: []
      }
      itinerary_items: {
        Row: {
          created_at: string | null
          date: string
          duration_minutes: number | null
          id: string
          notes: string | null
          place_id: string | null
          start_time: string | null
          title: string
          trip_id: string
        }
        Insert: {
          created_at?: string | null
          date: string
          duration_minutes?: number | null
          id?: string
          notes?: string | null
          place_id?: string | null
          start_time?: string | null
          title: string
          trip_id: string
        }
        Update: {
          created_at?: string | null
          date?: string
          duration_minutes?: number | null
          id?: string
          notes?: string | null
          place_id?: string | null
          start_time?: string | null
          title?: string
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "itinerary_items_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "saved_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "itinerary_items_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      quick_photos: {
        Row: {
          created_at: string | null
          id: string
          image_url: string
          place_id: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          image_url: string
          place_id?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          image_url?: string
          place_id?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quick_photos_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "saved_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quick_photos_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      reviews: {
        Row: {
          created_at: string | null
          flagged: boolean | null
          helpful_count: number | null
          id: string
          moderation_status: string | null
          place_id: string
          rating: number
          review_text: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          flagged?: boolean | null
          helpful_count?: number | null
          id?: string
          moderation_status?: string | null
          place_id: string
          rating: number
          review_text?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          flagged?: boolean | null
          helpful_count?: number | null
          id?: string
          moderation_status?: string | null
          place_id?: string
          rating?: number
          review_text?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reviews_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "saved_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_places: {
        Row: {
          address: string | null
          created_at: string | null
          google_place_id: string | null
          id: string
          is_visited: boolean | null
          latitude: number | null
          longitude: number | null
          name: string
          notes: string | null
          opening_hours: string[] | null
          phone_number: string | null
          photo_reference: string | null
          place_type: string | null
          price_level: string | null
          rating: number | null
          user_id: string
          user_ratings_total: number | null
          visited_at: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          created_at?: string | null
          google_place_id?: string | null
          id?: string
          is_visited?: boolean | null
          latitude?: number | null
          longitude?: number | null
          name: string
          notes?: string | null
          opening_hours?: string[] | null
          phone_number?: string | null
          photo_reference?: string | null
          place_type?: string | null
          price_level?: string | null
          rating?: number | null
          user_id: string
          user_ratings_total?: number | null
          visited_at?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          created_at?: string | null
          google_place_id?: string | null
          id?: string
          is_visited?: boolean | null
          latitude?: number | null
          longitude?: number | null
          name?: string
          notes?: string | null
          opening_hours?: string[] | null
          phone_number?: string | null
          photo_reference?: string | null
          place_type?: string | null
          price_level?: string | null
          rating?: number | null
          user_id?: string
          user_ratings_total?: number | null
          visited_at?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "saved_places_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      trip_places: {
        Row: {
          added_at: string | null
          id: string
          place_id: string
          trip_id: string
        }
        Insert: {
          added_at?: string | null
          id?: string
          place_id: string
          trip_id: string
        }
        Update: {
          added_at?: string | null
          id?: string
          place_id?: string
          trip_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trip_places_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "saved_places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trip_places_trip_id_fkey"
            columns: ["trip_id"]
            isOneToOne: false
            referencedRelation: "trips"
            referencedColumns: ["id"]
          },
        ]
      }
      trips: {
        Row: {
          created_at: string | null
          destination_city: string
          destination_country: string | null
          end_date: string
          id: string
          image_url: string | null
          is_active: boolean | null
          notes: string | null
          start_date: string
          updated_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          destination_city: string
          destination_country?: string | null
          end_date: string
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          notes?: string | null
          start_date: string
          updated_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          destination_city?: string
          destination_country?: string | null
          end_date?: string
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          notes?: string | null
          start_date?: string
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "trips_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_badges: {
        Row: {
          badge_id: string
          earned_at: string | null
          id: string
          user_id: string
        }
        Insert: {
          badge_id: string
          earned_at?: string | null
          id?: string
          user_id: string
        }
        Update: {
          badge_id?: string
          earned_at?: string | null
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_badges_badge_id_fkey"
            columns: ["badge_id"]
            isOneToOne: false
            referencedRelation: "badges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_challenges: {
        Row: {
          challenge_id: string
          completed_at: string | null
          created_at: string | null
          id: string
          is_completed: boolean | null
          progress: number | null
          user_id: string
        }
        Insert: {
          challenge_id: string
          completed_at?: string | null
          created_at?: string | null
          id?: string
          is_completed?: boolean | null
          progress?: number | null
          user_id: string
        }
        Update: {
          challenge_id?: string
          completed_at?: string | null
          created_at?: string | null
          id?: string
          is_completed?: boolean | null
          progress?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_challenges_challenge_id_fkey"
            columns: ["challenge_id"]
            isOneToOne: false
            referencedRelation: "challenges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_challenges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          current_streak: number | null
          dietary_preferences: string[] | null
          display_name: string
          email: string | null
          fitness_level: string | null
          home_city: string | null
          id: string
          longest_streak: number | null
          total_xp: number | null
          updated_at: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          current_streak?: number | null
          dietary_preferences?: string[] | null
          display_name: string
          email?: string | null
          fitness_level?: string | null
          home_city?: string | null
          id: string
          longest_streak?: number | null
          total_xp?: number | null
          updated_at?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          current_streak?: number | null
          dietary_preferences?: string[] | null
          display_name?: string
          email?: string | null
          fitness_level?: string | null
          home_city?: string | null
          id?: string
          longest_streak?: number | null
          total_xp?: number | null
          updated_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
